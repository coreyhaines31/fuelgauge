import Foundation

/// Where one limit is headed: the current percent, how fast it's climbing, and whether it lasts until reset.
public struct Forecast: Sendable, Equatable {
    public enum Verdict: Sendable, Equatable {
        /// Not enough history yet to trust a pace.
        case learning
        /// The limit is used up until it resets.
        case limitReached
        /// The window reset since the last reading; usage starts again from zero.
        case reset
        /// At this pace, the limit lasts until reset, ending near `projectedPercent`.
        case makesIt(projectedPercent: Double)
        /// At this pace, the limit runs out at `at`, before the reset. `earliest` and `latest` come from the
        /// fastest and slowest recent pace; `latest` is nil when the slowest pace makes it.
        case runsOut(at: Date, earliest: Date, latest: Date?)
    }

    public let key: LimitKey
    public let windowMinutes: Int?
    public let usedPercent: Double
    public let resetsAt: Date
    public let lastReadingAt: Date
    /// Percentage points per hour over the recent stretch; nil while learning.
    public let ratePerHour: Double?
    /// The highest pace that still lasts until reset, in percentage points per hour.
    public let budgetPerHour: Double?
    public let verdict: Verdict
    /// This window's readings, oldest first, for the chart.
    public let history: [Reading]

    public var windowName: String { WindowName.of(windowMinutes: windowMinutes) }

    /// Running out before reset, or already out: what alerts and the menu bar color care about.
    public var isShort: Bool {
        switch verdict {
        case .runsOut, .limitReached: true
        default: false
        }
    }
}

public enum ForecastEngine {
    /// How much history a pace needs before it's shown.
    public static let minimumCoverage: TimeInterval = 10 * 60

    /// One forecast per limit in `readings`, in a stable order.
    public static func forecasts(from readings: [Reading], now: Date = Date()) -> [Forecast] {
        Dictionary(grouping: readings, by: \.key)
            .compactMap { forecast(for: $0.value, now: now) }
            .sorted { $0.key < $1.key }
    }

    /// The recent stretch a pace is measured over: a fifth of the window, between 1 hour and 1 day.
    public static func lookback(windowMinutes: Int?) -> TimeInterval {
        guard let windowMinutes else { return 24 * 3600 }
        return min(max(Double(windowMinutes) * 60 / 5, 3600), 24 * 3600)
    }

    /// The forecast for one limit's readings.
    public static func forecast(for readings: [Reading], now: Date = Date()) -> Forecast? {
        let sorted = readings.filter { $0.at <= now }.sorted { $0.at < $1.at }
        guard let latest = sorted.last else { return nil }
        // Readings belong to the current window when they share its reset time (a little drift is normal).
        let window = sorted.filter { abs($0.resetsAt.timeIntervalSince(latest.resetsAt)) <= 10 * 60 }
        let used = latest.usedPercent

        func make(_ verdict: Forecast.Verdict, rate: Double? = nil, budget: Double? = nil) -> Forecast {
            Forecast(
                key: latest.key, windowMinutes: latest.windowMinutes, usedPercent: used,
                resetsAt: latest.resetsAt, lastReadingAt: latest.at, ratePerHour: rate,
                budgetPerHour: budget, verdict: verdict, history: window
            )
        }

        if latest.resetsAt <= now { return make(.reset) }
        let hoursLeft = latest.resetsAt.timeIntervalSince(now) / 3600
        let budget = max(0, 100 - used) / hoursLeft
        if used >= 100 { return make(.limitReached, budget: 0) }

        let windowStart = latest.windowMinutes.map { latest.resetsAt.addingTimeInterval(-Double($0) * 60) }
        let span = lookback(windowMinutes: latest.windowMinutes)
        guard let rate = pace(window, windowStart: windowStart, since: now.addingTimeInterval(-span), now: now) else {
            return make(.learning, budget: budget)
        }
        let others = [span / 2, span * 2].compactMap {
            pace(window, windowStart: windowStart, since: now.addingTimeInterval(-$0), now: now)
        }
        let fastest = ([rate] + others).max() ?? rate
        let slowest = ([rate] + others).min() ?? rate

        guard let runsOut = runOut(used: used, rate: rate, now: now), runsOut < latest.resetsAt else {
            return make(.makesIt(projectedPercent: min(100, used + rate * hoursLeft)), rate: rate, budget: budget)
        }
        let earliest = runOut(used: used, rate: fastest, now: now) ?? runsOut
        let latestRunOut = runOut(used: used, rate: slowest, now: now).flatMap { $0 < latest.resetsAt ? $0 : nil }
        return make(.runsOut(at: runsOut, earliest: earliest, latest: latestRunOut), rate: rate, budget: budget)
    }

    /// When the limit hits 100% at `rate`, or nil if it isn't climbing.
    static func runOut(used: Double, rate: Double, now: Date) -> Date? {
        guard rate > 0 else { return nil }
        return now.addingTimeInterval((100 - used) / rate * 3600)
    }

    /// Percentage points per hour since `start`: the climb from the last known value at `start` to now.
    /// Between readings the percent is assumed flat, since it only moves when the tool is used. Nil when
    /// the readings cover less than `minimumCoverage`, or there's a single reading and no known window start.
    static func pace(_ window: [Reading], windowStart: Date?, since start: Date, now: Date) -> Double? {
        guard let latest = window.last else { return nil }
        let from: Date
        let baseline: Double
        let windowStartsInside = windowStart.map { $0 >= start } ?? false
        // One reading says nothing about pace unless the window's zero point is known.
        guard window.count >= 2 || windowStartsInside else { return nil }
        if let before = window.last(where: { $0.at <= start }) {
            (from, baseline) = (start, before.usedPercent)
        } else if let windowStart, windowStart >= start {
            // The window began inside the stretch, at zero.
            (from, baseline) = (windowStart, 0)
        } else if let first = window.first {
            (from, baseline) = (first.at, first.usedPercent)
        } else {
            return nil
        }
        let elapsed = now.timeIntervalSince(from)
        guard elapsed >= minimumCoverage else { return nil }
        return max(0, latest.usedPercent - baseline) / (elapsed / 3600)
    }
}
