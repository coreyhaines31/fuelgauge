import Foundation

public struct TokenUsage: Codable, Equatable, Sendable {
    public var input: Int64 = 0
    public var output: Int64 = 0
    public var cacheRead: Int64 = 0
    public var cacheWrite: Int64 = 0
    public var cacheWriteLong: Int64 = 0
    public var reasoning: Int64 = 0

    public init(input: Int64 = 0, output: Int64 = 0, cacheRead: Int64 = 0,
                cacheWrite: Int64 = 0, cacheWriteLong: Int64 = 0, reasoning: Int64 = 0) {
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheWrite = cacheWrite
        self.cacheWriteLong = cacheWriteLong
        self.reasoning = reasoning
    }

    public var prompt: Int64 { input + cacheRead + cacheWrite }
    public var total: Int64 { prompt + output }
    public var cacheHitRate: Double? { prompt > 0 ? Double(cacheRead) / Double(prompt) : nil }

    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(input: lhs.input + rhs.input, output: lhs.output + rhs.output,
             cacheRead: lhs.cacheRead + rhs.cacheRead, cacheWrite: lhs.cacheWrite + rhs.cacheWrite,
             cacheWriteLong: lhs.cacheWriteLong + rhs.cacheWriteLong, reasoning: lhs.reasoning + rhs.reasoning)
    }
}

public struct UsageEvent: Codable, Identifiable, Sendable {
    public var id: String
    public var provider: Provider
    public var session: String
    public var project: String
    public var model: String
    public var at: Date
    public var tokens: TokenUsage

    public init(id: String, provider: Provider, session: String, project: String, model: String,
                at: Date, tokens: TokenUsage) {
        self.id = id
        self.provider = provider
        self.session = session
        self.project = project
        self.model = model
        self.at = at
        self.tokens = tokens
    }
}

public struct UsageSummary: Sendable {
    public let tokens: TokenUsage
    public let estimatedCost: Double
    public let unpricedEvents: Int
    public let sessions: Int
    public let events: Int

    public init(_ records: [UsageEvent]) {
        tokens = records.reduce(TokenUsage()) { $0 + $1.tokens }
        let prices = records.map { UsagePricing.cost(model: $0.model, tokens: $0.tokens) }
        estimatedCost = prices.compactMap { $0 }.reduce(0, +)
        unpricedEvents = prices.filter { $0 == nil }.count
        sessions = Set(records.map { "\($0.provider.rawValue)/\($0.session)" }).count
        events = records.count
    }

    public var costLabel: String {
        guard events > unpricedEvents else { return "Unavailable" }
        let amount = estimatedCost.formatted(.currency(code: "USD"))
        return unpricedEvents > 0 ? "\(amount) + unpriced" : amount
    }
}

public enum UsagePeriod: Int, CaseIterable, Sendable {
    case today = 1, week = 7, month = 30

    public var title: String {
        switch self {
        case .today: "Today"
        case .week: "7 days"
        case .month: "30 days"
        }
    }

    public func interval(now: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.date(byAdding: .day, value: 1 - rawValue, to: calendar.startOfDay(for: now))!
        return DateInterval(start: start, end: now)
    }

    public func previousInterval(now: Date, calendar: Calendar = .current) -> DateInterval {
        let current = interval(now: now, calendar: calendar)
        return DateInterval(start: calendar.date(byAdding: .day, value: -rawValue, to: current.start)!,
                            end: calendar.date(byAdding: .day, value: -rawValue, to: now)!)
    }
}

public enum UsageHistory {
    public static func select(_ events: [UsageEvent], interval: DateInterval,
                              provider: Provider? = nil) -> [UsageEvent] {
        events.filter {
            $0.at >= interval.start && $0.at < interval.end && (provider == nil || $0.provider == provider)
        }
    }

    public static func deduplicate(_ events: [UsageEvent]) -> [UsageEvent] {
        var unique: [String: UsageEvent] = [:]
        for event in events {
            if let prior = unique[event.id], prior.tokens.total > event.tokens.total { continue }
            unique[event.id] = event
        }
        return unique.values.sorted { $0.at == $1.at ? $0.id < $1.id : $0.at < $1.at }
    }
}
