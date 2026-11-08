import Foundation

/// Continued usage at the current session's pace, independent of the normal reset forecast.
public struct SessionPlan: Sendable {
    public struct Projection: Sendable, Equatable {
        public let ratePerHour: Double
        public let usedPercent: Double
        public let until: Date
        public let runsOutAt: Date?
        public let stopsAtReset: Bool
    }

    public enum Outcome: Sendable, Equatable {
        case projected(Projection)
        case needsFreshReading, needsActivity, inactive, reset, exhausted
    }

    public struct Limit: Sendable, Identifiable {
        public let forecast: Forecast
        public let outcome: Outcome
        public var id: LimitKey { forecast.key }
    }

    public let startsAt: Date
    public let endsAt: Date
    public let limits: [Limit]

    public init?(forecasts: [Forecast], minutes: Int, now: Date) {
        guard (1...240).contains(minutes) else { return nil }
        let end = now.addingTimeInterval(Double(minutes) * 60)
        startsAt = now
        endsAt = end
        limits = forecasts.map { Limit(forecast: $0, outcome: Self.project($0, until: end, now: now)) }
    }

    public var firstExhaustion: Limit? {
        limits.filter { exhaustionTime($0) != nil }.min {
            (exhaustionTime($0) ?? .distantFuture) < (exhaustionTime($1) ?? .distantFuture)
        }
    }

    public var hasUnknownUsage: Bool {
        limits.isEmpty || limits.contains {
            if case .projected(let projection) = $0.outcome { return projection.stopsAtReset }
            return $0.outcome != .exhausted || endsAt >= $0.forecast.resetsAt
        }
    }

    public func exhaustionTime(_ limit: Limit) -> Date? {
        if limit.outcome == .exhausted { return startsAt }
        if case .projected(let projection) = limit.outcome { return projection.runsOutAt }
        return nil
    }

    private static func project(_ forecast: Forecast, until end: Date, now: Date) -> Outcome {
        guard forecast.lastReadingAt <= now, forecast.verdict != .stale else { return .needsFreshReading }
        guard forecast.resetsAt > now, forecast.verdict != .reset else { return .reset }
        if forecast.usedPercent >= 100 || forecast.verdict == .limitReached { return .exhausted }
        guard now.timeIntervalSince(forecast.lastReadingAt) <= 900 else { return .needsFreshReading }
        guard let rate = AdaptiveForecast.sessionRate(forecast.history, now: now) else { return .needsActivity }
        guard rate > 0 else { return .inactive }
        let until = min(end, forecast.resetsAt)
        let used = min(100, forecast.usedPercent + rate * until.timeIntervalSince(now) / 3600)
        let out = ForecastEngine.runOut(used: forecast.usedPercent, rate: rate, now: now)
            .flatMap { $0 <= end && $0 < forecast.resetsAt ? $0 : nil }
        return .projected(Projection(ratePerHour: rate, usedPercent: used, until: until,
                                     runsOutAt: out, stopsAtReset: end >= forecast.resetsAt))
    }
}
