import Foundation

enum AdaptiveForecast {
    static func make(_ readings: [Reading], now: Date, calendar: Calendar) -> Forecast? {
        let timeline = ReadingTimeline(readings.filter {
            $0.at >= now.addingTimeInterval(-ForecastEngine.historyDuration)
        }, now: now)
        guard let window = timeline.segments.last, let latest = window.last else { return nil }
        let correction = timeline.segments.dropLast().last?.last.map {
            ReadingTimeline.sameWindow($0, latest)
        } ?? false
        guard var forecast = ForecastEngine.recentForecast(for: window, now: now,
                                                          windowStartAllowed: !correction) else { return nil }
        if forecast.verdict == .reset { return forecast }
        let maximumAge: TimeInterval = (latest.windowMinutes ?? 10080) <= 300 ? 3600 : 6 * 3600
        if timeline.hasConflict || (now.timeIntervalSince(latest.at) > maximumAge && latest.usedPercent < 100) {
            forecast.verdict = .stale
            return forecast
        }
        if forecast.verdict == .limitReached { return forecast }
        let activeRate = sessionRate(window, now: now)
        if let activeRate, let at = ForecastEngine.runOut(used: latest.usedPercent, rate: activeRate, now: now),
           at < latest.resetsAt, at.timeIntervalSince(now) <= 5 * 3600 {
            forecast.sessionRunsOutAt = at
        }
        guard (latest.windowMinutes ?? 10080) >= 1440,
              !correction,
              let schedule = UsageSchedule(timeline.intervals, now: now, calendar: calendar),
              latest.resetsAt.timeIntervalSince(now) <= 35 * 86400 else { return forecast }
        return project(forecast, schedule: schedule, activeRate: activeRate, now: now)
    }

    private static func sessionRate(_ window: [Reading], now: Date) -> Double? {
        guard let latest = window.last, now.timeIntervalSince(latest.at) <= 900 else { return nil }
        let recent = window.filter { $0.at >= now.addingTimeInterval(-3600) }
        guard let first = recent.first, recent.count >= 2,
              now.timeIntervalSince(first.at) >= 600,
              zip(recent, recent.dropFirst()).allSatisfy({ $1.at.timeIntervalSince($0.at) <= 1800 }) else { return nil }
        return max(0, latest.usedPercent - first.usedPercent) / (now.timeIntervalSince(first.at) / 3600)
    }

    private static func project(_ original: Forecast, schedule: UsageSchedule,
                                activeRate: Double?, now: Date) -> Forecast {
        var forecast = original
        forecast.basis = .schedule
        var at = now
        var used = forecast.usedPercent
        forecast.projection = [.init(at: at, usedPercent: used)]
        while at < forecast.resetsAt {
            let end = min(at.addingTimeInterval(900), forecast.resetsAt)
            let midpoint = at.addingTimeInterval(end.timeIntervalSince(at) / 2)
            let ahead = midpoint.timeIntervalSince(now) / 3600
            let trend = 1 + (schedule.recentMultiplier - 1) * exp(-ahead / 48)
            guard let expectedRate = schedule.rate(at: midpoint) ?? forecast.ratePerHour else { return original }
            let usual = expectedRate * trend
            let weight = activeRate.map { $0 > 0 ? exp(-ahead / 2) : 0 } ?? 0
            let rate = usual * (1 - weight) + (activeRate ?? 0) * weight
            let next = used + rate * end.timeIntervalSince(at) / 3600
            if next >= 100, rate > 0 {
                let out = at.addingTimeInterval((100 - used) / rate * 3600)
                forecast.projection.append(.init(at: out, usedPercent: 100))
                // These are scenario estimates, not calibrated confidence bounds.
                forecast.verdict = out < forecast.resetsAt
                    ? .runsOut(at: out, earliest: out, latest: out) : .makesIt(projectedPercent: 100)
                return forecast
            }
            (at, used) = (end, next)
            forecast.projection.append(.init(at: at, usedPercent: used))
        }
        forecast.verdict = .makesIt(projectedPercent: used)
        return forecast
    }
}
