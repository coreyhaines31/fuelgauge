import Foundation

/// A coding tool whose plan limits Fuel Gauge tracks. A struct rather than an enum so a new tool is one line.
public struct Provider: RawRepresentable, Hashable, Codable, Sendable, Comparable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let claude = Provider(rawValue: "claude")
    public static let codex = Provider(rawValue: "codex")
    public static let grokBot = Provider(rawValue: "grok-bot")
    public static let cursor = Provider(rawValue: "cursor")

    public static let all: [Provider] = [.claude, .codex, .grokBot, .cursor]

    public var name: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .grokBot: "Grok Bot"
        case .cursor: "Cursor"
        default: rawValue
        }
    }

    public static func < (lhs: Provider, rhs: Provider) -> Bool {
        let order = all.map(\.rawValue)
        return (order.firstIndex(of: lhs.rawValue) ?? order.count) < (order.firstIndex(of: rhs.rawValue) ?? order.count)
    }
}

/// One limit of one tool, like Claude's 5-hour window or Codex's weekly window.
public struct LimitKey: Hashable, Codable, Sendable, Comparable {
    public let provider: Provider
    public let limit: String

    public init(provider: Provider, limit: String) {
        self.provider = provider
        self.limit = limit
    }

    public var id: String { "\(provider.rawValue)/\(limit)" }

    public static func < (lhs: LimitKey, rhs: LimitKey) -> Bool {
        lhs.provider == rhs.provider ? lhs.limit < rhs.limit : lhs.provider < rhs.provider
    }
}

/// How much of a limit was used at one moment, and when that limit resets.
public struct Reading: Codable, Hashable, Sendable {
    public var provider: Provider
    public var limit: String
    /// The window's length when the tool says so. Nil for limits tied to a billing period.
    public var windowMinutes: Int?
    public var usedPercent: Double
    public var resetsAt: Date
    public var at: Date

    public init(provider: Provider, limit: String, windowMinutes: Int?, usedPercent: Double, resetsAt: Date, at: Date) {
        self.provider = provider
        self.limit = limit
        self.windowMinutes = windowMinutes
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.at = at
    }

    public var key: LimitKey { LimitKey(provider: provider, limit: limit) }

    enum CodingKeys: String, CodingKey {
        case provider = "p", limit = "l", windowMinutes = "w", usedPercent = "u", resetsAt = "r", at = "t"
    }
}

public enum WindowName {
    /// "5-hour", "Weekly", "Daily", or "Monthly" for a billing period.
    public static func of(windowMinutes: Int?) -> String {
        switch windowMinutes {
        case nil: "Monthly"
        case 10080: "Weekly"
        case 1440: "Daily"
        case let minutes? where minutes % 60 == 0: "\(minutes / 60)-hour"
        case let minutes?: "\(minutes)-minute"
        }
    }
}
