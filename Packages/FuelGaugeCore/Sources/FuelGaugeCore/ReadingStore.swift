import Foundation

/// Readings on disk, one JSON line each, in a file per tool per month: `Readings/claude-2026-10.jsonl`.
/// The app and the `fuelgauge statusline` command both append, so files are only ever appended to or
/// deleted whole, never rewritten.
public struct ReadingStore: Sendable {
    public let folder: URL
    /// How long an unchanged reading is skipped before it's written again.
    public var unchangedInterval: TimeInterval = 10 * 60

    public init(folder: URL = Brand.supportFolder.appending(path: "Readings")) {
        self.folder = folder
    }

    /// Appends the readings that add something: a new percent, a new reset time, or the first in a while.
    @discardableResult
    public func append(_ readings: [Reading]) throws -> [Reading] {
        guard !readings.isEmpty else { return [] }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var latest: [LimitKey: Reading] = [:]
        var written: [Reading] = []
        for reading in readings.sorted(by: { $0.at < $1.at }) {
            let previous = latest[reading.key] ?? lastReading(for: reading.key)
            if let previous, !adds(reading, after: previous) { continue }
            try write(reading)
            latest[reading.key] = reading
            written.append(reading)
        }
        return written
    }

    func adds(_ reading: Reading, after previous: Reading) -> Bool {
        guard reading.at > previous.at else { return false }
        return reading.usedPercent != previous.usedPercent
            || abs(reading.resetsAt.timeIntervalSince(previous.resetsAt)) > 60
            || reading.at.timeIntervalSince(previous.at) >= unchangedInterval
    }

    /// Every reading taken since `date`, oldest first.
    public func load(since date: Date, provider: Provider? = nil) -> [Reading] {
        files(since: date, provider: provider)
            .flatMap(Self.readings(in:))
            .filter { $0.at >= date }
            .sorted { $0.at < $1.at }
    }

    /// Deletes month files that ended before `date`.
    public func prune(before date: Date) {
        for url in allFiles() {
            guard let month = Self.month(of: url), let end = Calendar.utc.date(byAdding: .month, value: 1, to: month),
                  end < date else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Files

    private func write(_ reading: Reading) throws {
        let url = folder.appending(path: "\(reading.provider.rawValue)-\(Self.monthName(reading.at)).jsonl")
        var line = try Self.encoder.encode(reading)
        line.append(0x0A)
        // O_APPEND keeps concurrent writers from overwriting each other's lines.
        let descriptor = open(url.path, O_WRONLY | O_APPEND | O_CREAT, 0o644)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { close(descriptor) }
        let count = line.withUnsafeBytes { Darwin.write(descriptor, $0.baseAddress, $0.count) }
        guard count == line.count else { throw CocoaError(.fileWriteUnknown) }
    }

    private func lastReading(for key: LimitKey) -> Reading? {
        let candidates = allFiles()
            .filter { $0.lastPathComponent.hasPrefix(key.provider.rawValue + "-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for url in candidates {
            if let reading = Self.readings(in: url, tailBytes: 64 * 1024).last(where: { $0.key == key }) {
                return reading
            }
        }
        return nil
    }

    private func allFiles() -> [URL] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return names.filter { $0.hasSuffix(".jsonl") }.map { folder.appending(path: $0) }
    }

    private func files(since date: Date, provider: Provider?) -> [URL] {
        let first = Calendar.utc.dateInterval(of: .month, for: date)?.start ?? date
        return allFiles().filter { url in
            if let provider, !url.lastPathComponent.hasPrefix(provider.rawValue + "-") { return false }
            guard let month = Self.month(of: url) else { return false }
            return month >= first
        }
    }

    static func readings(in url: URL) -> [Reading] {
        readings(in: url, tailBytes: nil)
    }

    private static func readings(in url: URL, tailBytes: Int?) -> [Reading] {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? handle.close() }
        var skipFirstLine = false
        if let tailBytes, let size = try? handle.seekToEnd(), size > UInt64(tailBytes) {
            try? handle.seek(toOffset: size - UInt64(tailBytes))
            skipFirstLine = true
        } else {
            try? handle.seek(toOffset: 0)
        }
        guard let data = try? handle.readToEnd() else { return [] }
        var lines = data.split(separator: 0x0A)
        if skipFirstLine, !lines.isEmpty { lines.removeFirst() }
        return lines.compactMap { try? decoder.decode(Reading.self, from: Data($0)) }
    }

    private static func month(of url: URL) -> Date? {
        let name = url.deletingPathExtension().lastPathComponent
        guard name.count > 8 else { return nil }
        return monthFormatter.date(from: String(name.suffix(7)))
    }

    private static func monthName(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
}
