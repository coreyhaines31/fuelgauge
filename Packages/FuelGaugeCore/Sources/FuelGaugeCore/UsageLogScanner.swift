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
        let cutoff = Calendar.current.date(byAdding: .day, value: -61, to: now)!
        for root in roots where enabled.contains(root.provider) {
            scan(root, cutoff: cutoff)
        }
        for path in Array(files.keys) {
            let recent = files[path]?.events.filter { $0.value.at >= cutoff } ?? [:]
            files[path]?.events = recent
        }
        if let cacheURL {
            do {
                try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                try JSONEncoder().encode(files).write(to: cacheURL, options: .atomic)
            } catch { warnings.append("Usage history could not be saved; it will be rebuilt on restart.") }
        }
        return UsageHistory.deduplicate(files.values.flatMap { $0.events.values }.filter {
            enabled.contains($0.provider) && $0.at >= cutoff && $0.at <= now
        })
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
            while let newline = pending.firstIndex(of: 0x0A) {
                let line = Data(pending[..<newline])
                state.offset += UInt64(line.count + 1)
                pending.removeSubrange(...newline)
                if let event = state.parser.parse(line, provider: provider), event.at >= cutoff {
                    if let prior = state.events[event.id], prior.tokens.total > event.tokens.total { continue }
                    state.events[event.id] = event
                }
            }
        }
        state.modified = modified
        state.size = size
        files[url.path] = state
    }
}
