import Foundation

/// The words for a forecast, shared by the menu bar panel, alerts, the `fuelgauge` command, and the Claude
/// Code status line, so they never disagree.
public enum ForecastText {
    /// "Makes it to reset", "Runs out around 3:40p, 1h 20m before reset", and so on.
    public static func headline(_ forecast: Forecast, now: Date = Date()) -> String {
        switch forecast.verdict {
        case .learning:
            "Learning your pace"
        case .limitReached:
            "Out until \(time(forecast.resetsAt, now: now))"
        case .reset:
            "Reset. Fresh window"
        case .makesIt(let projected):
            if projected >= 99.5 {
                "Makes it to reset, just"
            } else if projected < 1 {
                "Makes it to reset"
            } else {
                "Makes it to reset, about \(percent(projected)) by then"
            }
        case .runsOut(let at, _, _):
            "Runs out around \(time(at, now: now)), \(duration(forecast.resetsAt.timeIntervalSince(at))) early"
        }
    }

    /// "23% used · resets 5:00p (in 3h 7m)".
    public static func usage(_ forecast: Forecast, now: Date = Date()) -> String {
        if forecast.verdict == .reset { return "Was \(percent(forecast.usedPercent)) before the reset" }
        let resets = forecast.resetsAt
        return "\(percent(forecast.usedPercent)) used · resets \(time(resets, now: now)) "
            + "(in \(duration(resets.timeIntervalSince(now))))"
    }

    /// "Using 6% an hour. You can use up to 9% an hour and still make it." Close to the reset, when more is left
    /// than an hour could use, it says how much is left instead.
    public static func pace(_ forecast: Forecast, now: Date = Date()) -> String? {
        switch forecast.verdict {
        case .learning:
            let needed = duration(ForecastEngine.minimumCoverage(windowMinutes: forecast.windowMinutes))
            return "A forecast needs \(needed) of readings while you work."
        case .limitReached, .reset:
            return nil
        case .makesIt, .runsOut:
            guard let rate = forecast.ratePerHour, let budget = forecast.budgetPerHour else { return nil }
            let left = max(0, 100 - forecast.usedPercent)
            let using: String
            if rate < 0.05 {
                let lookback = ForecastEngine.lookback(windowMinutes: forecast.windowMinutes)
                let stretch = lookback == 3600 ? "hour" : lookback == 86400 ? "day" : duration(lookback)
                using = "Not used in the last \(stretch)."
            } else {
                using = "Using \(rate: rate) an hour."
            }
            if budget >= left {
                let untilReset = duration(forecast.resetsAt.timeIntervalSince(now))
                return "\(using) \(percent(left)) left for the \(untilReset) until the reset."
            }
            return "\(using) You can use up to \(rate: budget) an hour and still make it."
        }
    }

    /// The range behind a run-out time: "Between 2:50p and 4:30p at your recent pace."
    public static func range(_ forecast: Forecast, now: Date = Date()) -> String? {
        guard case .runsOut(_, let earliest, let latest) = forecast.verdict else { return nil }
        guard let latest else {
            return "As early as \(time(earliest, now: now)), or not before reset if you slow down."
        }
        guard latest.timeIntervalSince(earliest) >= 10 * 60 else { return nil }
        return "Between \(time(earliest, now: now)) and \(time(latest, now: now)) at your recent pace."
    }

    /// One short segment for the Claude Code status line: "5h 23% ok", "wk 81% out ~Thu 2p".
    public static func strip(_ forecast: Forecast, now: Date = Date()) -> String {
        let label = shortName(forecast.windowMinutes)
        let used = percent(forecast.usedPercent)
        switch forecast.verdict {
        case .learning: return "\(label) \(used) learning"
        case .limitReached: return "\(label) out til \(time(forecast.resetsAt, now: now))"
        case .reset: return "\(label) reset"
        case .makesIt: return "\(label) \(used) ok"
        case .runsOut(let at, _, _): return "\(label) \(used) out ~\(time(at, now: now))"
        }
    }

    public static func shortName(_ windowMinutes: Int?) -> String {
        switch windowMinutes {
        case nil: "mo"
        case 10080: "wk"
        case 1440: "day"
        case let minutes? where minutes % 60 == 0: "\(minutes / 60)h"
        case let minutes?: "\(minutes)m"
        }
    }

    public static func percent(_ value: Double) -> String {
        value > 0 && value < 1 ? "<1%" : "\(Int(value.rounded()))%"
    }

    /// "3:40p" today, "Fri 9a" within a week, "Oct 24" after that.
    public static func time(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let clock = "\(hour % 12 == 0 ? 12 : hour % 12)" + (minute == 0 ? "" : String(format: ":%02d", minute))
            + (hour < 12 ? "a" : "p")
        if calendar.isDate(date, inSameDayAs: now) { return clock }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day ?? 0
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if days < 7 {
            formatter.dateFormat = "EEE"
            return "\(formatter.string(from: date)) \(clock)"
        }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// "45m", "3h 7m", "2d 16h".
    public static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int((seconds / 60).rounded()))
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return minutes % 60 == 0 ? "\(hours)h" : "\(hours)h \(minutes % 60)m" }
        return hours % 24 == 0 ? "\(hours / 24)d" : "\(hours / 24)d \(hours % 24)h"
    }
}

extension String.StringInterpolation {
    /// "6%" or "0.4%" for a pace in percentage points per hour.
    mutating func appendInterpolation(rate: Double) {
        appendLiteral(rate >= 10 || rate == 0 ? "\(Int(rate.rounded()))%" : String(format: "%.1f%%", rate))
    }
}
