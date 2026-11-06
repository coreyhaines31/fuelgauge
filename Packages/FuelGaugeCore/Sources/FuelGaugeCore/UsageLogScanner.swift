import Foundation

public struct UsageLogScanner: Sendable {
    public struct Root: Sendable {
        public let provider: Provider
        public let url: URL

        public init(provider: Provider, url: URL) {
            self.provider = provider
            self.url = url
        }
    }

    private struct FileState: Codable, Sendable {
        var identity: UInt64
        var modified: Date
        var size: UInt64
        var offset: UInt64 = 0
        var parser: UsageLogParser
        var events: [String: UsageEvent] = [:]
    }

    private var files: [String: FileState] = [:]
    private let roots: [Root]
    private let cacheURL: URL?
    /// Something changed since the cache was last written.
    private var dirty = false
    private var savedAt: Date?
    /// Goes up with every change, so an unchanged scan can return the last result instead of rebuilding it.
    private var revision = 0
    private var lastResult: LastResult?

    private struct LastResult: Sendable {
        let revision: Int
        let enabled: [Provider]
        let events: [UsageEvent]
        /// An event stamped after `now` was left out and belongs in a later result, so this one can't be reused.
        let leftOutFuture: Bool
    }
    /// Writing the cache re-encodes every tracked file, so changes are batched. A crash only costs a re-read.
    static let saveInterval: TimeInterval = 600
    public private(set) var warnings: [String] = []

    public init(roots: [Root] = Self.defaultRoots, cacheURL: URL? = nil) {
        self.roots = roots
        self.cacheURL = cacheURL
        if let cacheURL, let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode([String: FileState].self, from: data) { files = cached }
    }

    public static var defaultRoots: [Root] {
        let environment = ProcessInfo.processInfo.environment
        let claude = environment["CLAUDE_CONFIG_DIR"].map { URL(filePath: $0) }
            ?? URL.homeDirectory.appending(path: ".claude")
        let codex = CodexLogReader.defaultRoot
        return [Root(provider: .claude, url: claude.appending(path: "projects")),
                Root(provider: .codex, url: codex),
                Root(provider: .codex, url: codex.deletingLastPathComponent().appending(path: "archived_sessions"))]
    }

    public mutating func scan(enabled: [Provider], now: Date = Date()) -> [UsageEvent] {
        warnings = []
        let tracked = files.count
        files = files.filter { path, _ in roots.contains { path.hasPrefix($0.url.path + "/") } }
        if files.count != tracked { markChanged() }
        let cutoff = Calendar.current.date(byAdding: .day, value: -61, to: now)!
        for root in roots where enabled.contains(root.provider) {
            scan(root, cutoff: cutoff)
        }
        for path in Array(files.keys) {
            let recent = files[path]?.events.filter { $0.value.at >= cutoff } ?? [:]
            if recent.count != files[path]?.events.count {
                files[path]?.events = recent
                markChanged()
            }
        }
        if let cacheURL, dirty, savedAt.map({ now.timeIntervalSince($0) >= Self.saveInterval }) ?? true {
            do {
                try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                try JSONEncoder().encode(files).write(to: cacheURL, options: .atomic)
                dirty = false
                savedAt = now
            } catch { warnings.append("Usage history could not be saved; it will be rebuilt on restart.") }
        }
        if let lastResult, lastResult.revision == revision, lastResult.enabled == enabled, !lastResult.leftOutFuture {
            return lastResult.events
        }
        let candidates = files.values.flatMap { $0.events.values }
            .filter { enabled.contains($0.provider) && $0.at >= cutoff }
        let events = UsageHistory.deduplicate(candidates.filter { $0.at <= now })
        lastResult = LastResult(revision: revision, enabled: enabled, events: events,
                                leftOutFuture: candidates.contains { $0.at > now })
        return events
    }

    private mutating func markChanged() {
        dirty = true
        revision += 1
    }

    private mutating func scan(_ root: Root, cutoff: Date) {
        guard FileManager.default.fileExists(atPath: root.url.path) else { return }
        var discoveryFailed = false
        let enumerator = FileManager.default.enumerator(
            at: root.url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles],
            errorHandler: { _, _ in discoveryFailed = true; return true }
        )
        guard let enumerator else {
            warnings.append("Could not read \(root.provider.name) history.")
            return
        }
        for case let url as URL in enumerator where url.pathExtension == "jsonl" {
            do { try scanFile(url, provider: root.provider, cutoff: cutoff) } catch {
                warnings.append("Some \(root.provider.name) history could not be read. Showing saved usage.")
            }
        }
        if discoveryFailed { warnings.append("Some \(root.provider.name) history folders could not be read.") }
        warnings = Array(Set(warnings)).sorted()
    }

    private mutating func scanFile(_ url: URL, provider: Provider, cutoff: Date) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,
              let modified = attributes[.modificationDate] as? Date,
              let size = attributes[.size] as? UInt64,
              let identity = attributes[.systemFileNumber] as? UInt64 else { return }
        if files[url.path] == nil && modified < cutoff { return }
        var state = files[url.path] ?? FileState(identity: identity, modified: .distantPast, size: 0,
                                                parser: UsageLogParser(session: url.lastPathComponent))
        if state.identity != identity || size < state.size || (size == state.size && modified != state.modified) {
            state = FileState(identity: identity, modified: .distantPast, size: 0,
                              parser: UsageLogParser(session: url.lastPathComponent))
        }
        guard size != state.size || modified != state.modified else { return }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: state.offset)
        var pending = Data()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            pending.append(chunk)
            guard let newline = pending.lastIndex(of: 0x0A) else { continue }
            let complete = pending[...newline]
            state.offset += UInt64(complete.count)
            for line in complete.split(separator: 0x0A) where Self.isUsageLine(line, provider: provider) {
                if let event = state.parser.parse(Data(line), provider: provider), event.at >= cutoff {
                    if let prior = state.events[event.id], prior.tokens.total > event.tokens.total { continue }
                    state.events[event.id] = event
                }
            }
            pending = Data(pending[pending.index(after: newline)...])
        }
        state.modified = modified
        state.size = size
        files[url.path] = state
        markChanged()
    }

    private static let claudeMarkers = [Data("\"usage\"".utf8)]
    private static let codexMarkers = ["\"token_count\"", "\"turn_context\"", "\"session_meta\""].map { Data($0.utf8) }

    private static func isUsageLine(_ line: Data.SubSequence, provider: Provider) -> Bool {
        let markers = provider == .claude ? claudeMarkers : codexMarkers
        return markers.contains { line.range(of: $0) != nil }
    }

}
