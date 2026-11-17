import Foundation
@testable import FuelGaugeCore
import Testing

struct ClaudeResetsTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func defaults() -> UserDefaults {
        let name = "FuelGaugeTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func roundTripsAndKeepsTheOlderKeysForWeekly() {
        let store = defaults()
        // Before Fable resets, Fuel Gauge stored one count, which reset the whole week.
        store.set(2, forKey: "claudeResetCount")
        store.set(now.timeIntervalSince1970, forKey: ClaudeResets.recordedAtKey)
        var resets = ClaudeResets.load(from: store)
        #expect(resets.weekly.available == 2)
        #expect(resets.fable.available == 0)
        resets.fable = .init(available: 3, expiresAt: now.addingTimeInterval(86400 * 100))
        resets.save(to: store)
        #expect(ClaudeResets.load(from: store) == resets)
    }

    @Test func nothingRecordedMeansNothingUsable() {
        let resets = ClaudeResets(fable: .init(available: 3))
        #expect(resets.usable(.fable, now: now) == 0)
        #expect(resets.warnings(now: now).isEmpty)
    }

    @Test func expiredCountsAreNotUsable() {
        let resets = ClaudeResets(fable: .init(available: 3, expiresAt: now.addingTimeInterval(-60)),
                                  weekly: .init(available: 1), recordedAt: now)
        #expect(resets.usable(.fable, now: now) == 0)
        #expect(resets.usable(.weekly, now: now) == 1)
        #expect(resets.summary(.fable, now: now) == "Recheck Fable resets")
        #expect(resets.summary(.weekly, now: now) == "1 weekly reset")
    }

    @Test func warnsBeforeResetsLapseUnused() {
        let resets = ClaudeResets(fable: .init(available: 3, expiresAt: now.addingTimeInterval(2 * 86400)),
                                  weekly: .init(available: 1, expiresAt: now.addingTimeInterval(30 * 86400)),
                                  recordedAt: now)
        let warnings = resets.warnings(now: now)
        #expect(warnings.map(\.kind) == [.fable])
        #expect(warnings.first?.text.hasPrefix("3 Fable resets expire ") == true)
        #expect(warnings.first?.text.hasSuffix(" if unused") == true)
        #expect(resets.expiry(.fable, now: now)?.hasPrefix("All expire ") == true)
        #expect(resets.expiry(.weekly, now: now)?.hasPrefix("Expires ") == true)
    }
}

struct ResetAdviceTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func forecast(_ limit: String, used: Double, rate: Double?, resetsIn hours: Double,
                          verdict: Forecast.Verdict) -> Forecast {
        Forecast(key: LimitKey(provider: .claude, limit: limit), windowMinutes: 10080, usedPercent: used,
                 resetsAt: now.addingTimeInterval(hours * 3600), lastReadingAt: now, ratePerHour: rate,
                 budgetPerHour: nil, verdict: verdict, history: [])
    }

    /// 80% used, 2%/hour, 20 hours left: runs out in 10 hours.
    private var shortWeek: Forecast {
        forecast("seven_day", used: 80, rate: 2, resetsIn: 20,
                 verdict: .runsOut(at: now.addingTimeInterval(10 * 3600), earliest: now, latest: nil))
    }

    private func usage(share: Double?) -> ClaudeUsage {
        ClaudeUsage(models: [.init(name: "Fable", usedPercent: 40, resetsAt: now.addingTimeInterval(20 * 3600),
                                   usedPercentOfWeekly: share, allowancePercentOfWeekly: 50)], checkedAt: now)
    }

    private func resets(fable: Int, weekly: Int, weeklyExpiry: Date? = nil) -> ClaudeResets {
        ClaudeResets(fable: .init(available: fable), weekly: .init(available: weekly, expiresAt: weeklyExpiry),
                     recordedAt: now)
    }

    @Test func fableResetWhenItsShareIsEnough() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 25),
                                         resets: resets(fable: 3, weekly: 1), now: now)
        #expect(advice?.kind == .fable)
        #expect(advice?.text == "Using a Fable reset gives back 25% of your week, "
                + "enough to reach the reset at this pace.")
    }

    @Test func weeklyResetWhenFableGivesBackTooLittle() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 18),
                                         resets: resets(fable: 3, weekly: 1), now: now)
        #expect(advice?.kind == .weekly)
        #expect(advice?.text.hasPrefix("Using a Fable reset gives back 18% of your week, but the week") == true)
        #expect(advice?.text.hasSuffix("A weekly reset starts your week over.") == true)
    }

    @Test func fableResetAloneSaysItStillRunsOut() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 18),
                                         resets: resets(fable: 3, weekly: 0), now: now)
        #expect(advice?.kind == .fable)
        #expect(advice?.text.contains("At this pace it still runs out around") == true)
    }

    @Test func noFableUseMeansAFableResetWontHelp() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 0),
                                         resets: resets(fable: 3, weekly: 1), now: now)
        #expect(advice?.kind == .weekly)
        #expect(ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 0),
                                    resets: resets(fable: 3, weekly: 0), now: now) == nil)
    }

    @Test func weeklyResetThatLapsesThisWeekGoesFirst() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 25),
                                         resets: resets(fable: 3, weekly: 1,
                                                        weeklyExpiry: now.addingTimeInterval(5 * 3600)),
                                         now: now)
        #expect(advice?.kind == .weekly)
        #expect(advice?.text.contains("before this week ends") == true)
    }

    @Test func unknownShareIsSaidHonestly() {
        let advice = ResetAdvice.suggest(forecasts: [shortWeek], usage: nil,
                                         resets: resets(fable: 2, weekly: 0), now: now)
        #expect(advice?.text == "A Fable reset gives back what Fable used this week. "
                + "Fuel Gauge can't see how much yet.")
        // A share from last week's window says nothing about this one.
        let old = ClaudeUsage(models: [.init(name: "Fable", usedPercent: 40, resetsAt: now.addingTimeInterval(-60),
                                             usedPercentOfWeekly: 30)], checkedAt: now)
        #expect(ResetAdvice.suggest(forecasts: [shortWeek], usage: old, resets: resets(fable: 2, weekly: 0),
                                    now: now)?.text.hasPrefix("A Fable reset gives back what") == true)
    }

    @Test func fableAllowanceRunningOut() {
        let fable = forecast("seven_day_model_fable", used: 90, rate: 5, resetsIn: 20,
                             verdict: .runsOut(at: now.addingTimeInterval(2 * 3600), earliest: now, latest: nil))
        let week = forecast("seven_day", used: 30, rate: 1, resetsIn: 20, verdict: .makesIt(projectedPercent: 50))
        let advice = ResetAdvice.suggest(forecasts: [week, fable], usage: usage(share: 22),
                                         resets: resets(fable: 1, weekly: 1), now: now)
        #expect(advice == ResetAdvice(kind: .fable,
                                      text: "Using a Fable reset refills Fable and gives back 22% of your week."))
    }

    @Test func nothingWhenEverythingLastsOrNoResets() {
        let week = forecast("seven_day", used: 30, rate: 1, resetsIn: 20, verdict: .makesIt(projectedPercent: 50))
        #expect(ResetAdvice.suggest(forecasts: [week], usage: usage(share: 10),
                                    resets: resets(fable: 3, weekly: 1), now: now) == nil)
        #expect(ResetAdvice.suggest(forecasts: [shortWeek], usage: usage(share: 10),
                                    resets: resets(fable: 0, weekly: 0), now: now) == nil)
    }
}
