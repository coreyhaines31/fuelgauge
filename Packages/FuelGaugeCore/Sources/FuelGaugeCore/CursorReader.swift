import Foundation
import SQLite3

/// Reads Cursor's monthly usage. Unlike the other tools, Cursor keeps no usage on disk, so this asks
/// cursor.com, signed in with the token the Cursor app already stores. It's the one reader that goes online,
/// so it's off until the person turns it on.
public struct CursorReader: Sendable {
    public let databaseURL: URL

    public init(databaseURL: URL = Self.defaultDatabase) {
        self.databaseURL = databaseURL
    }

    public static var defaultDatabase: URL {
        URL.applicationSupportDirectory.appending(path: "Cursor/User/globalStorage/state.vscdb")
    }

    public var isInstalled: Bool {
        FileManager.default.fileExists(atPath: databaseURL.path)
    }

    public func read(now: Date = Date()) async -> [Reading] {
        guard let token = accessToken(), let user = Self.userID(fromJWT: token),
              let url = URL(string: "https://cursor.com/api/usage-summary") else { return [] }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("WorkosCursorSessionToken=\(user)%3A%3A\(token)", forHTTPHeaderField: "Cookie")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        return Self.readings(from: data, at: now)
    }

    static func readings(from data: Data, at now: Date) -> [Reading] {
        guard let summary = try? JSONDecoder().decode(Summary.self, from: data),
              !summary.isUnlimited, let plan = summary.individualUsage?.plan, plan.enabled,
              let resetsAt = parseDate(summary.billingCycleEnd) else { return [] }
        // Cursor's own percent, else used over limit.
        let percent = plan.totalPercentUsed ?? plan.limit.flatMap { $0 > 0 ? plan.used / $0 * 100 : nil } ?? 0
        return [Reading(
            provider: .cursor, limit: "monthly", windowMinutes: nil,
            usedPercent: min(max(percent, 0), 100), resetsAt: resetsAt, at: now
        )]
    }

    /// The token from Cursor's settings database, opened read-only so Cursor is never disturbed.
    private func accessToken() -> String? {
        var database: OpaquePointer?
        let uri = "file:\(databaseURL.path)?mode=ro&immutable=1"
        guard sqlite3_open_v2(uri, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK else {
            sqlite3_close(database)
            return nil
        }
        defer { sqlite3_close(database) }
        var statement: OpaquePointer?
        let query = "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken'"
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW, let text = sqlite3_column_text(statement, 0) else { return nil }
        let token = String(cString: text).trimmingCharacters(in: CharacterSet(charactersIn: "\"\n "))
        return token.isEmpty ? nil : token
    }

    /// The user ID Cursor's session cookie pairs with the token: the last part of the JWT's `sub`.
    static func userID(fromJWT token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = claims["sub"] as? String else { return nil }
        return sub.split(separator: "|").last.map(String.init)
    }

    private static func parseDate(_ text: String?) -> Date? {
        guard let text else { return nil }
        if let date = try? Date(text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        return try? Date(text, strategy: .iso8601)
    }

    private struct Summary: Decodable {
        let billingCycleEnd: String?
        let isUnlimited: Bool
        let individualUsage: Usage?

        enum CodingKeys: String, CodingKey {
            case billingCycleEnd, isUnlimited, individualUsage
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            billingCycleEnd = try container.decodeIfPresent(String.self, forKey: .billingCycleEnd)
            isUnlimited = try container.decodeIfPresent(Bool.self, forKey: .isUnlimited) ?? false
            individualUsage = try container.decodeIfPresent(Usage.self, forKey: .individualUsage)
        }
    }

    private struct Usage: Decodable {
        let plan: Plan?
    }

    private struct Plan: Decodable {
        let enabled: Bool
        let used: Double
        let limit: Double?
        let totalPercentUsed: Double?
    }
}
