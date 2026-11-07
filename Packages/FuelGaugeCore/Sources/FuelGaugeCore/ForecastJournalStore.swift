import Foundation

public struct ForecastJournalStore: Sendable {
    public let url: URL
    public private(set) var journal = ForecastJournal()
    private var loaded = false
    private var fingerprint: Fingerprint?

    private struct Fingerprint: Equatable, Sendable {
        let modified: Date?
        let size: UInt64?
        let inode: UInt64?
    }

    public init(url: URL) { self.url = url }

    public mutating func refresh(forecasts: [Forecast], readings: [Reading], now: Date,
                                 appVersion: String) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let descriptor = open(url.appendingPathExtension("lock").path, O_WRONLY | O_CREAT, 0o600)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else { throw CocoaError(.fileLocking) }
        defer { flock(descriptor, LOCK_UN) }
        let current = try fileFingerprint()
        if !loaded || current != fingerprint {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let saved = current == nil ? ForecastJournal() : try decoder.decode(
                ForecastJournal.self, from: Data(contentsOf: url)
            )
            guard saved.schemaVersion == 1 else { throw CocoaError(.coderReadCorrupt) }
            journal = saved
            fingerprint = current
            loaded = true
        }
        var updated = journal
        updated.update(forecasts: forecasts, readings: readings, now: now, appVersion: appVersion)
        guard updated != journal else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        try encoder.encode(updated).write(to: url, options: .atomic)
        journal = updated
        fingerprint = try fileFingerprint()
    }

    private func fileFingerprint() throws -> Fingerprint? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return Fingerprint(modified: attributes[.modificationDate] as? Date,
                               size: attributes[.size] as? UInt64, inode: attributes[.systemFileNumber] as? UInt64)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }
}
