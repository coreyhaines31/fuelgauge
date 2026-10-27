import Foundation

public struct ResetCredits: Decodable, Sendable {
    public let availableCount: Int
    public let credits: [Credit]?

    public struct Credit: Decodable, Sendable {
        public let status: String
        public let expiresAt: Date?
    }

    public static func decode(_ data: Data) throws -> ResetCredits? {
        struct Response: Decodable { let rateLimitResetCredits: ResetCredits? }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let value = try decoder.decode(Response.self, from: data).rateLimitResetCredits
        guard let value, value.availableCount >= 0 else { return nil }
        return value
    }

    public var nextExpiration: Date? {
        credits?.filter { $0.status == "available" }.compactMap(\.expiresAt).min()
    }

    public func summary(now: Date = Date()) -> String {
        // Counts may include credits that expired since the last account refresh.
        if let expiry = nextExpiration, expiry <= now { return "Reset availability needs refreshing" }
        switch availableCount {
        case 0: return "No resets available"
        case 1: return "1 reset available"
        default: return "\(availableCount) resets available"
        }
    }
}
