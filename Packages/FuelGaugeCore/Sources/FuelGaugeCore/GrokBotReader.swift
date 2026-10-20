import Foundation

/// Reads Grok Bot's weekly usage from the cache it keeps on disk. Grok Bot stores app state as JSON blobs
/// whose file names are base32-encoded keys; the one ending in `.weekly-usage.cache` holds the percent used
/// and the next reset. It only refreshes while Grok Bot is running, so each reading carries Grok Bot's own
/// read time.
public struct GrokBotReader: Sendable {
    public let folder: URL

    public init(folder: URL = Self.defaultFolder) {
        self.folder = folder
    }

    public static var defaultFolder: URL {
        URL.applicationSupportDirectory.appending(path: "Grok Bot/sand-client-persistence")
    }

    public var isInstalled: Bool {
        FileManager.default.fileExists(atPath: folder.path)
    }

    public func read() -> [Reading] {
        guard let url = cacheFile(), let data = try? Data(contentsOf: url),
              let blob = try? JSONDecoder().decode(Blob.self, from: data),
              blob.value.kind == "present", let reading = blob.value.reading,
              let usage = reading.usage else { return [] }
        return [Reading(
            provider: .grokBot, limit: "weekly", windowMinutes: 10080,
            usedPercent: usage.percentUsed,
            resetsAt: Date(timeIntervalSince1970: usage.nextResetMs / 1000),
            at: Date(timeIntervalSince1970: reading.readAtMs / 1000)
        )]
    }

    /// The signed-in account's usage cache. If more than one account has one, the newest wins.
    private func cacheFile() -> URL? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        let matches = names.filter { name in
            guard let stem = name.split(separator: ".").first,
                  let decoded = Base32.decode(String(stem)),
                  let key = String(data: decoded, encoding: .utf8) else { return false }
            return key.hasSuffix(".weekly-usage.cache")
        }
        return matches
            .map { folder.appending(path: $0) }
            .max { modified($0) < modified($1) }
    }

    private func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private struct Blob: Decodable {
        let value: Value
    }

    private struct Value: Decodable {
        let kind: String
        let reading: CachedReading?
    }

    private struct CachedReading: Decodable {
        let usage: Usage?
        let readAtMs: Double
    }

    private struct Usage: Decodable {
        let percentUsed: Double
        let nextResetMs: Double
    }
}

/// RFC 4648 base32, case-insensitive, padding optional.
enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8)

    static func decode(_ text: String) -> Data? {
        var bits = 0
        var value = 0
        var output = Data()
        for character in text.uppercased().utf8 where character != UInt8(ascii: "=") {
            guard let index = alphabet.firstIndex(of: character) else { return nil }
            value = (value << 5) | index
            bits += 5
            if bits >= 8 {
                output.append(UInt8((value >> (bits - 8)) & 0xFF))
                bits -= 8
            }
        }
        return output
    }
}
