import Foundation

/// Retrospective replay by source timestamp. Imported readings may not have been available live then.
public enum ForecastBacktest {
    public struct Result: Encodable, Sendable {
        public let tool: String
        public let limit: String
        public let horizonHours: Int
        public var eligible = 0
        public var recentForecasts = 0
        public var adaptiveForecasts = 0
        public var pairedForecasts = 0
        public var scheduledForecasts = 0
        public var recentError = 0.0
        public var adaptiveError = 0.0
        public var recentMissedExhaustions = 0
        public var adaptiveMissedExhaustions = 0
        public var recentEarlyExhaustions = 0
        public var adaptiveEarlyExhaustions = 0

        public var recentMAE: Double? { pairedForecasts > 0 ? recentError / Double(pairedForecasts) : nil }
        public var adaptiveMAE: Double? { pairedForecasts > 0 ? adaptiveError / Double(pairedForecasts) : nil }

        mutating func record(actual: Reading, origin: Date, recent: Forecast?, adaptive: Forecast?) {
            eligible += 1
            let old = recent.flatMap { ForecastBacktest.projectedUsage($0, at: actual.at, origin: origin) }
            let new = adaptive.flatMap { ForecastBacktest.projectedUsage($0, at: actual.at, origin: origin) }
            if old != nil { recentForecasts += 1 }
            if new != nil { adaptiveForecasts += 1 }
            guard let old, let new else { return }
            pairedForecasts += 1
            if adaptive?.basis == .schedule { scheduledForecasts += 1 }
            recentError += abs(old - actual.usedPercent)
            adaptiveError += abs(new - actual.usedPercent)
            if actual.usedPercent >= 100 {
                if old < 100 { recentMissedExhaustions += 1 }
                if new < 100 { adaptiveMissedExhaustions += 1 }
            } else {
                if old >= 100 { recentEarlyExhaustions += 1 }
                if new >= 100 { adaptiveEarlyExhaustions += 1 }
            }
        }
    }

    public static func run(_ readings: [Reading], since: Date, now: Date = Date(),
                           calendar: Calendar = .current) -> [Result] {
        Dictionary(grouping: readings.filter { $0.at <= now }, by: \.key)
            .sorted { $0.key < $1.key }
            .flatMap { key, data in
                replay(data.sorted { $0.at < $1.at }, key: key, since: since, now: now, calendar: calendar)
            }
    }

    private static func replay(_ data: [Reading], key: LimitKey, since: Date, now: Date,
                               calendar: Calendar) -> [Result] {
        guard let first = data.first, let last = data.last else { return [] }
        let start = max(since, first.at)
        var origin = Date(timeIntervalSince1970: ceil(start.timeIntervalSince1970 / 3600) * 3600)
        var results = [1, 6, 24].map { Result(tool: key.provider.rawValue, limit: key.limit, horizonHours: $0) }
        while origin < min(now, last.at) {
            let history = data.filter { $0.at <= origin }
            let timeline = ReadingTimeline(history, now: origin)
            if let latest = timeline.segments.last?.last, latest.usedPercent < 100, !timeline.hasConflict {
                let recent = ForecastEngine.forecast(for: history, now: origin, method: .recent, calendar: calendar)
                let adaptive = ForecastEngine.forecast(for: history, now: origin, method: .adaptive, calendar: calendar)
                for index in results.indices {
                    let target = origin.addingTimeInterval(Double(results[index].horizonHours) * 3600)
                    if let actual = outcome(data, latest: latest, origin: origin, target: target) {
                        results[index].record(actual: actual, origin: origin, recent: recent, adaptive: adaptive)
                    }
                }
            }
            origin = origin.addingTimeInterval(3600)
        }
        return results
    }

    private static func outcome(_ data: [Reading], latest: Reading, origin: Date, target: Date) -> Reading? {
        guard let candidate = data.first(where: { $0.at >= target }),
              candidate.at.timeIntervalSince(target) <= 900,
              candidate.at < latest.resetsAt,
              ReadingTimeline.sameWindow(candidate, latest) else { return nil }
        let timeline = ReadingTimeline(data.filter { $0.at <= candidate.at }, now: candidate.at)
        guard !timeline.hasConflict, let segment = timeline.segments.last,
              let first = segment.first, first.at <= origin, let actual = segment.last,
              actual.at == candidate.at, actual.usedPercent >= latest.usedPercent else { return nil }
        return actual
    }

    static func projectedUsage(_ forecast: Forecast, at date: Date, origin: Date) -> Double? {
        switch forecast.verdict {
        case .learning, .stale, .reset, .limitReached: return nil
        case .makesIt, .runsOut: break
        }
        if let first = forecast.projection.first {
            if date <= first.at { return first.usedPercent }
            var previous = first
            for point in forecast.projection.dropFirst() {
                if date <= point.at {
                    let fraction = date.timeIntervalSince(previous.at) / point.at.timeIntervalSince(previous.at)
                    return previous.usedPercent + (point.usedPercent - previous.usedPercent) * fraction
                }
                previous = point
            }
            return previous.usedPercent
        }
        guard let rate = forecast.ratePerHour else { return nil }
        return min(100, forecast.usedPercent + rate * max(0, date.timeIntervalSince(origin)) / 3600)
    }
}
