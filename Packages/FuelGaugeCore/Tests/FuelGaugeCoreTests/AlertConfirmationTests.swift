import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct AlertConfirmationTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let planner = AlertPlanner(settings: .init(alertWhenShort: true, thresholds: []))

    func short(readingOffset: TimeInterval = 0, resetOffset: TimeInterval = 0,
               windowMinutes: Int = 10080) -> Forecast {
        let out = now.addingTimeInterval(2 * 3600)
        return Forecast(key: LimitKey(provider: .codex, limit: "weekly"), windowMinutes: windowMinutes,
                        usedPercent: 40, resetsAt: now.addingTimeInterval(4 * 3600 + resetOffset),
                        lastReadingAt: now.addingTimeInterval(readingOffset), ratePerHour: 30, budgetPerHour: 15,
                        verdict: .runsOut(at: out, earliest: out, latest: out), history: [])
    }

    @Test func refreshingTheSameReadingCannotConfirmAWarning() {
        let forecast = short()
        var state = AlertPlanner.State()
        for minute in 0...5 {
            let (alerts, next) = planner.plan([forecast], state: state,
                                              now: now.addingTimeInterval(Double(minute) * 60))
            #expect(alerts.isEmpty)
            state = next
        }
    }

    @Test func aNewWindowNeedsItsOwnConfirmation() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let next = short(readingOffset: 60, resetOffset: 7 * 86400)
        let (alerts, first) = planner.plan([next], state: pending, now: now.addingTimeInterval(60))
        #expect(alerts.isEmpty)
        let confirming = short(readingOffset: 120, resetOffset: 7 * 86400)
        let (confirmed, _) = planner.plan([confirming], state: first, now: now.addingTimeInterval(120))
        #expect(confirmed.count == 1)
    }

    @Test func oldReadingsCannotConfirmEvenBeforeTheForecastBecomesStale() {
        let (_, pending) = planner.plan([short(readingOffset: -3 * 3600)], state: .init(), now: now)
        let (alerts, _) = planner.plan([short(readingOffset: -2 * 3600)], state: pending,
                                       now: now.addingTimeInterval(60))
        #expect(alerts.isEmpty)
    }

    @Test func aLongPauseExpiresPendingConfirmation() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let (alerts, _) = planner.plan([short(readingOffset: 1800)], state: pending,
                                       now: now.addingTimeInterval(1800))
        #expect(alerts.isEmpty)
    }

    @Test func aSecondFreshReadingConfirmsAfterDuplicateRefreshes() {
        let (_, first) = planner.plan([short()], state: .init(), now: now)
        let (_, duplicate) = planner.plan([short()], state: first, now: now.addingTimeInterval(30))
        let (alerts, fired) = planner.plan([short(readingOffset: 60)], state: duplicate,
                                          now: now.addingTimeInterval(60))
        #expect(alerts.map(\.id) == ["codex/weekly|short"])
        let (again, _) = planner.plan([short(readingOffset: 120)], state: fired,
                                      now: now.addingTimeInterval(120))
        #expect(again.isEmpty)
    }

    @Test func interruptedForecastsRequireTwoNewReadings() {
        let verdicts: [Forecast.Verdict] = [.stale, .learning, .reset, .limitReached, .makesIt(projectedPercent: 70)]
        for verdict in verdicts {
            let (_, first) = planner.plan([short()], state: .init(), now: now)
            var interrupted = short(readingOffset: 60)
            interrupted.verdict = verdict
            let (_, cleared) = planner.plan([interrupted], state: first, now: now.addingTimeInterval(60))
            #expect(cleared.pendingShorts.isEmpty)
            let (alerts, pending) = planner.plan([short(readingOffset: 120)], state: cleared,
                                                now: now.addingTimeInterval(120))
            #expect(alerts.isEmpty)
            let (confirmed, _) = planner.plan([short(readingOffset: 180)], state: pending,
                                              now: now.addingTimeInterval(180))
            #expect(confirmed.count == 1)
        }
    }

    @Test func missingOrDisabledLimitsClearConfirmation() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let (_, absent) = planner.plan([], state: pending, now: now.addingTimeInterval(60))
        #expect(absent.pendingShorts.isEmpty)
        let disabled = AlertPlanner(settings: .init(alertWhenShort: false, thresholds: []))
        let (_, off) = disabled.plan([short(readingOffset: 60)], state: pending, now: now.addingTimeInterval(60))
        #expect(off.pendingShorts.isEmpty)
    }

    @Test func backwardsAndFutureTimestampsCannotConfirmOrSeedAReplay() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let (backwards, cleared) = planner.plan([short(readingOffset: -60)], state: pending,
                                                now: now.addingTimeInterval(60))
        #expect(backwards.isEmpty)
        #expect(cleared.pendingShorts.isEmpty)
        let (replay, _) = planner.plan([short()], state: cleared, now: now.addingTimeInterval(120))
        #expect(replay.isEmpty)
        let (future, next) = planner.plan([short(readingOffset: 180)], state: pending,
                                          now: now.addingTimeInterval(60))
        #expect(future.isEmpty)
        #expect(next.pendingShorts.isEmpty)
    }

    @Test func confirmationExpiresAfterFifteenMinutes() {
        for elapsed in [900.0, 901.0] {
            let (_, pending) = planner.plan([short()], state: .init(), now: now)
            let (alerts, _) = planner.plan([short(readingOffset: elapsed)], state: pending,
                                           now: now.addingTimeInterval(elapsed))
            #expect(alerts.count == (elapsed == 900 ? 1 : 0))
        }
    }

    @Test func changedWindowLengthOrLowerUsageNeedsNewConfirmation() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let shorter = short(readingOffset: 60, windowMinutes: 1440)
        let (changed, _) = planner.plan([shorter], state: pending, now: now.addingTimeInterval(60))
        #expect(changed.isEmpty)
        let original = short(readingOffset: 60)
        let lower = Forecast(key: original.key, windowMinutes: original.windowMinutes, usedPercent: 30,
                             resetsAt: original.resetsAt, lastReadingAt: original.lastReadingAt,
                             ratePerHour: original.ratePerHour, budgetPerHour: original.budgetPerHour,
                             verdict: original.verdict, history: [])
        let (corrected, _) = planner.plan([lower], state: pending, now: now.addingTimeInterval(60))
        #expect(corrected.isEmpty)
    }

    @Test func aRestartKeepsDeduplicationButDropsPendingConfirmation() {
        let (_, pending) = planner.plan([short()], state: .init(), now: now)
        let restoredPending = AlertPlanner.State(fired: pending.fired)
        let (first, fresh) = planner.plan([short(readingOffset: 60)], state: restoredPending,
                                         now: now.addingTimeInterval(60))
        #expect(first.isEmpty)
        let (confirmed, fired) = planner.plan([short(readingOffset: 120)], state: fresh,
                                              now: now.addingTimeInterval(120))
        #expect(confirmed.count == 1)
        let restoredFired = AlertPlanner.State(fired: fired.fired)
        let (_, next) = planner.plan([short(readingOffset: 180)], state: restoredFired,
                                     now: now.addingTimeInterval(180))
        let (duplicate, _) = planner.plan([short(readingOffset: 240)], state: next,
                                          now: now.addingTimeInterval(240))
        #expect(duplicate.isEmpty)
    }
}
