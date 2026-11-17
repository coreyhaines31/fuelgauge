import Foundation

/// When Claude's week (or its Fable allowance) won't last, which saved reset fixes it most cheaply. Advice
/// only: Fuel Gauge can't use a reset, so the text says what a reset would do, never that one was used.
public struct ResetAdvice: Equatable, Sendable {
    public let kind: ClaudeResets.Kind
    /// A short headline: "Fix: a Fable reset", or "A Fable reset helps, but not enough".
    public let title: String
    public let text: String

    public init(kind: ClaudeResets.Kind, title: String, text: String) {
        self.kind = kind
        self.title = title
        self.text = text
    }

    public static func suggest(forecasts: [Forecast], usage: ClaudeUsage?, resets: ClaudeResets,
                               now: Date = Date()) -> ResetAdvice? {
        let claude = forecasts.filter { $0.key.provider == .claude && $0.verdict != .reset }
        let week = claude.first { $0.key.limit == "seven_day" }
        let fable = claude.first { $0.modelName?.caseInsensitiveCompare("Fable") == .orderedSame }
        let share = fableShare(usage, week: week, now: now)
        if let week, week.isShort {
            return forWeek(week, share: share, resets: resets, now: now)
        }
        if let fable, fable.isShort, resets.usable(.fable, now: now) > 0 {
            let back = share.flatMap { $0 >= 1 ? " and gives back \(ForecastText.percent($0)) of your week" : nil }
            return ResetAdvice(kind: .fable, title: fix(.fable),
                               text: "Using a Fable reset refills Fable\(back ?? "").")
        }
        return nil
    }

    private static func forWeek(_ week: Forecast, share: Double?, resets: ClaudeResets, now: Date) -> ResetAdvice? {
        let fableResets = resets.usable(.fable, now: now)
        let weeklyResets = resets.usable(.weekly, now: now)
        // A weekly reset that lapses before this week ends costs nothing to use now.
        if weeklyResets > 0, let expiry = resets.weekly.expiresAt, expiry < week.resetsAt {
            let when = ForecastText.time(expiry, now: now)
            return weekly(week, now: now, title: "Fix: your expiring weekly reset",
                          lead: "Yours expires \(when), before this week ends.")
        }
        if fableResets > 0, let share {
            guard share >= 1 else {
                return weeklyResets > 0
                    ? weekly(week, now: now,
                             lead: "Fable hasn't used any of this week, so a Fable reset wouldn't help.")
                    : nil
            }
            let back = "Using a Fable reset gives back \(ForecastText.percent(share)) of your week"
            switch runsOut(week, used: max(0, week.usedPercent - share), now: now) {
            case .lasts:
                return ResetAdvice(kind: .fable, title: fix(.fable),
                                   text: "\(back), enough to reach the reset at this pace.")
            case .runsOut(let at) where weeklyResets > 0:
                return weekly(week, now: now, lead: "\(back), but the week would still run out around "
                              + "\(ForecastText.time(at, now: now)).")
            case .runsOut(let at):
                return ResetAdvice(kind: .fable, title: "A Fable reset helps, but not enough",
                                   text: "\(back). At this pace it still runs out around "
                                   + "\(ForecastText.time(at, now: now)).")
            case .unknown where weeklyResets > 0:
                return ResetAdvice(kind: .fable, title: "Try a Fable reset first",
                                   text: "\(back). If that's not enough, a weekly reset starts your week over.")
            case .unknown:
                return ResetAdvice(kind: .fable, title: "A Fable reset would help", text: "\(back).")
            }
        }
        if weeklyResets > 0 { return weekly(week, now: now) }
        if fableResets > 0 {
            return ResetAdvice(kind: .fable, title: "A Fable reset might help",
                               text: "A Fable reset gives back what Fable used this week. "
                               + "Fuel Gauge can't see how much yet.")
        }
        return nil
    }

    /// A weekly reset, checked against the pace: a fresh week at this pace may run out too.
    private static func weekly(_ week: Forecast, now: Date, title: String? = nil, lead: String? = nil) -> ResetAdvice {
        var sentences = lead.map { [$0] } ?? []
        if case .runsOut(let at) = runsOut(week, used: 0, from: now, resetsAt: now.addingTimeInterval(7 * 86400)) {
            sentences.append("A weekly reset starts your week over, but at this pace a fresh week runs out in "
                             + "about \(ForecastText.duration(at.timeIntervalSince(now))).")
            return ResetAdvice(kind: .weekly, title: "A weekly reset helps, but not enough",
                               text: sentences.joined(separator: " "))
        }
        sentences.append("A weekly reset starts your week over.")
        return ResetAdvice(kind: .weekly, title: title ?? fix(.weekly), text: sentences.joined(separator: " "))
    }

    private static func fix(_ kind: ClaudeResets.Kind) -> String {
        "Fix: a \(kind.phrase) reset"
    }

    private enum Outcome { case lasts, runsOut(Date), unknown }

    /// Whether the week lasts at its current pace from `used` percent.
    private static func runsOut(_ week: Forecast, used: Double, now: Date) -> Outcome {
        runsOut(week, used: used, from: now, resetsAt: week.resetsAt)
    }

    private static func runsOut(_ week: Forecast, used: Double, from now: Date, resetsAt: Date) -> Outcome {
        guard let rate = week.ratePerHour else { return .unknown }
        guard rate > 0 else { return .lasts }
        let at = now.addingTimeInterval((100 - used) / rate * 3600)
        return at >= resetsAt ? .lasts : .runsOut(at)
    }

    /// Fable's share of this week. Zero when a check made this week lists no Fable allowance; nil when it's
    /// unknown (no check this week, or Claude didn't report the share).
    private static func fableShare(_ usage: ClaudeUsage?, week: Forecast?, now: Date) -> Double? {
        guard let usage else { return nil }
        if let fable = usage.model(named: "Fable") {
            return fable.resetsAt > now ? fable.usedPercentOfWeekly : nil
        }
        guard let week, usage.checkedAt > week.resetsAt.addingTimeInterval(-7 * 86400) else { return nil }
        return 0
    }
}
