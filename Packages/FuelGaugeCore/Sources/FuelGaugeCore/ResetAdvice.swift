import Foundation

/// When Claude's week (or its Fable allowance) won't last, which saved reset fixes it most cheaply. Advice
/// only: Fuel Gauge can't use a reset, so the text says what a reset would do, never that one was used.
public struct ResetAdvice: Equatable, Sendable {
    public let kind: ClaudeResets.Kind
    public let text: String

    public static func suggest(forecasts: [Forecast], usage: ClaudeUsage?, resets: ClaudeResets,
                               now: Date = Date()) -> ResetAdvice? {
        let claude = forecasts.filter { $0.key.provider == .claude && $0.verdict != .reset }
        let week = claude.first { $0.key.limit == "seven_day" }
        let fable = claude.first { $0.modelName?.caseInsensitiveCompare("Fable") == .orderedSame }
        let share = fableShare(usage, now: now)
        if let week, week.isShort {
            return forWeek(week, share: share, resets: resets, now: now)
        }
        if let fable, fable.isShort, resets.usable(.fable, now: now) > 0 {
            let back = share.flatMap { $0 >= 1 ? " and gives back \(ForecastText.percent($0)) of your week" : nil }
            return ResetAdvice(kind: .fable, text: "Using a Fable reset refills Fable\(back ?? "").")
        }
        return nil
    }

    private static func forWeek(_ week: Forecast, share: Double?, resets: ClaudeResets, now: Date) -> ResetAdvice? {
        let fableResets = resets.usable(.fable, now: now)
        let weeklyResets = resets.usable(.weekly, now: now)
        let weeklyText = "A weekly reset starts your week over."
        // A weekly reset that lapses before this week ends costs nothing to use now.
        if weeklyResets > 0, let expiry = resets.weekly.expiresAt, expiry < week.resetsAt {
            let when = ForecastText.time(expiry, now: now)
            return ResetAdvice(kind: .weekly, text: "\(weeklyText) Yours expires \(when), before this week ends.")
        }
        if fableResets > 0, let share {
            guard share >= 1 else {
                return weeklyResets > 0
                    ? ResetAdvice(kind: .weekly, text: "Fable hasn't used any of this week, so a Fable reset "
                                  + "wouldn't help. \(weeklyText)")
                    : nil
            }
            let back = "Using a Fable reset gives back \(ForecastText.percent(share)) of your week"
            switch runsOut(week, givenBack: share, now: now) {
            case .lasts:
                return ResetAdvice(kind: .fable, text: "\(back), enough to reach the reset at this pace.")
            case .runsOut(let at) where weeklyResets > 0:
                return ResetAdvice(kind: .weekly, text: "\(back), but the week would still run out around "
                                   + "\(ForecastText.time(at, now: now)). \(weeklyText)")
            case .runsOut(let at):
                return ResetAdvice(kind: .fable, text: "\(back). At this pace it still runs out around "
                                   + "\(ForecastText.time(at, now: now)).")
            case .unknown where weeklyResets > 0:
                return ResetAdvice(kind: .fable, text: "\(back). If that's not enough, \(weeklyText.lowercased())")
            case .unknown:
                return ResetAdvice(kind: .fable, text: "\(back).")
            }
        }
        if weeklyResets > 0 { return ResetAdvice(kind: .weekly, text: weeklyText) }
        if fableResets > 0 {
            return ResetAdvice(kind: .fable, text: "A Fable reset gives back what Fable used this week. "
                               + "Fuel Gauge can't see how much yet.")
        }
        return nil
    }

    private enum Outcome { case lasts, runsOut(Date), unknown }

    /// Whether the week lasts at its current pace once `givenBack` points come off it.
    private static func runsOut(_ week: Forecast, givenBack: Double, now: Date) -> Outcome {
        guard let rate = week.ratePerHour else { return .unknown }
        let used = max(0, week.usedPercent - givenBack)
        guard rate > 0 else { return .lasts }
        let at = now.addingTimeInterval((100 - used) / rate * 3600)
        return at >= week.resetsAt ? .lasts : .runsOut(at)
    }

    /// Fable's share of this week, from a reading for the current window.
    private static func fableShare(_ usage: ClaudeUsage?, now: Date) -> Double? {
        guard let fable = usage?.model(named: "Fable"), fable.resetsAt > now else { return nil }
        return fable.usedPercentOfWeekly
    }
}
