import Foundation

/// The shape of `fuelgauge resets --json`: Claude's recorded resets by kind, its per-model allowances, and
/// what the planner suggests. Stable snake_case keys for scripts and agents.
public struct ResetsJSON: Encodable {
    public struct Kind: Encodable {
        /// As recorded, which may be out of date.
        public let available: Int
        /// What can still be used: zero once the recorded expiry has passed.
        public let usable: Int
        public let expiresAt: Date?
        public let expiresSoon: Bool
        public let explanation: String
    }

    public struct Allowance: Encodable {
        public let model: String
        public let usedPercent: Double
        public let usedPercentOfWeekly: Double?
        public let allowancePercentOfWeekly: Double?
        public let resetsAt: Date
        public let checkedAt: Date
    }

    public struct Advice: Encodable {
        public let reset: String
        public let title: String
        public let text: String
    }

    public struct Claude: Encodable {
        /// Reset counts are typed in by the person; Claude doesn't share them with other apps.
        public let source = "manual"
        public let recordedAt: Date?
        public let fable: Kind
        public let weekly: Kind
        public let allowances: [Allowance]
        public let advice: Advice?
    }

    public let claude: Claude

    public init(resets: ClaudeResets, usage: ClaudeUsage?, advice: ResetAdvice?, now: Date = Date()) {
        func kind(_ kind: ClaudeResets.Kind) -> Kind {
            let balance = resets[kind]
            return Kind(available: resets.recordedAt == nil ? 0 : balance.available,
                        usable: resets.usable(kind, now: now),
                        expiresAt: resets.recordedAt == nil ? nil : balance.expiresAt,
                        expiresSoon: resets.expiresSoon(kind, now: now), explanation: kind.explanation)
        }
        let allowances = (usage?.models ?? []).filter { $0.resetsAt > now }.map {
            Allowance(model: $0.name, usedPercent: $0.usedPercent, usedPercentOfWeekly: $0.usedPercentOfWeekly,
                      allowancePercentOfWeekly: $0.allowancePercentOfWeekly, resetsAt: $0.resetsAt,
                      checkedAt: usage?.checkedAt ?? now)
        }
        claude = Claude(recordedAt: resets.recordedAt, fable: kind(.fable), weekly: kind(.weekly),
                        allowances: allowances,
                        advice: advice.map { Advice(reset: $0.kind.rawValue, title: $0.title, text: $0.text) })
    }

    public static func encode(_ value: ResetsJSON) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}
