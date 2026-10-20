import Foundation

/// Reads Codex's limits from its session logs. Every `token_count` event in `~/.codex/sessions/**/*.jsonl`
/// carries `rate_limits` with each window's used percent, length, and reset time, so this needs no
/// network and no sign-in. It remembers how far it read each file, so each poll only reads what's new.
public struct CodexLogReader: Sendable {
    public struct State: Codable, Sendable {
        public var offsets: [String: UInt64] = [:]
        public init() {}
    }

    public let root: URL
    public var state: State
    /// How far back the first read goes, so a weekly window has history from the start.
    public var backfill: TimeInterval = 8 * 24 * 3600

    public init(root: URL = Self.defaultRoot, state: State = State()) {
        self.root = root
        self.state = state
    }

    public static var defaultRoot: URL {
        let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"].map { URL(filePath: $0) }
        return (codexHome ?? URL.homeDirectory.appending(path: ".codex")).appending(path: "sessions")
    }

    public var isInstalled: Bool {
        FileManager.default.fileExists(atPath: root.path)
    }

    /// Reads every new line in session files changed in the backfill period.
    public mutating func poll(now: Date = Date()) -> [Reading] {
        let cutoff = now.addingTimeInterval(-backfill)
        var readings: [Reading] = []
        var seen: Set<String> = []
        for (url, modified) in sessionFiles() where modified >= cutoff {
            seen.insert(url.path)
            let offset = state.offsets[url.path] ?? 0
            let (lines, end) = Self.newLines(in: url, from: offset)
            state.offsets[url.path] = end
            readings += lines.flatMap(Self.readings(fromLine:))
        }
        // Forget files that dropped out of the backfill period.
        state.offsets = state.offsets.filter { seen.contains($0.key) }
        return readings.filter { $0.at >= cutoff }
    }

    private func sessionFiles() -> [(URL, Date)] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else { return [] }
        var files: [(URL, Date)] = []
        for case let url as URL in enumerator where url.pathExtension == "jsonl" {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  let modified = values.contentModificationDate else { continue }
            files.append((url, modified))
        }
        return files
    }

    /// Complete lines after `offset` that mention `rate_limits`, and where the next read should start. Reads
    /// in chunks, since a long session's log can pass 80 MB. A half-written last line is left for the next poll.
    static func newLines(in url: URL, from offset: UInt64, chunkSize: Int = 4 << 20) -> ([Data], UInt64) {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return ([], offset) }
        defer { try? handle.close() }
        guard let size = try? handle.seekToEnd() else { return ([], offset) }
        // A file that shrank was replaced: start over.
        var position = offset > size ? 0 : offset
        guard size > position else { return ([], position) }
        try? handle.seek(toOffset: position)
        var lines: [Data] = []
        var pending = Data()
        while let chunk = try? handle.read(upToCount: chunkSize), !chunk.isEmpty {
            pending.append(chunk)
            guard let lastNewline = pending.lastIndex(of: 0x0A) else { continue }
            let complete = pending[pending.startIndex...lastNewline]
            lines += complete.split(separator: 0x0A).filter { $0.range(of: marker) != nil }.map { Data($0) }
            position += UInt64(complete.count)
            pending = Data(pending[pending.index(after: lastNewline)...])
        }
        return (lines, position)
    }

    private static let marker = Data("\"rate_limits\"".utf8)

    static func readings(fromLine line: Data) -> [Reading] {
        guard line.range(of: marker) != nil,
              let event = try? decoder.decode(Event.self, from: line),
              let limits = event.payload?.rateLimits,
              let at = parseDate(event.timestamp) else { return [] }
        let name = limits.limitId ?? "codex"
        return [limits.primary, limits.secondary].compactMap { window in
            guard let window, let minutes = window.windowMinutes, let resetsAt = window.resetsAt else { return nil }
            return Reading(
                provider: .codex, limit: "\(name)-\(minutes)", windowMinutes: minutes,
                usedPercent: window.usedPercent, resetsAt: Date(timeIntervalSince1970: resetsAt), at: at
            )
        }
    }

    private static func parseDate(_ text: String?) -> Date? {
        guard let text else { return nil }
        if let date = try? Date(text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        return try? Date(text, strategy: .iso8601)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private struct Event: Decodable {
        let timestamp: String?
        let payload: Payload?
    }

    private struct Payload: Decodable {
        let rateLimits: RateLimits?
    }

    private struct RateLimits: Decodable {
        let limitId: String?
        let primary: Window?
        let secondary: Window?
    }

    private struct Window: Decodable {
        let usedPercent: Double
        let windowMinutes: Int?
        let resetsAt: Double?
    }
}
