import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct SessionPlanBoundaryTests {
    let fixtures = SessionPlanTests()

    @Test func refusesOldConflictingAndFutureSourceReadings() throws {
        let old = try fixtures.forecast(age: 901)
        var conflict = try fixtures.forecast()
        conflict.verdict = .stale
        let future = Forecast(key: old.key, windowMinutes: old.windowMinutes, usedPercent: old.usedPercent,
            resetsAt: old.resetsAt, lastReadingAt: fixtures.now.addingTimeInterval(1), ratePerHour: old.ratePerHour,
            budgetPerHour: old.budgetPerHour, verdict: .learning, history: old.history)
        for forecast in [old, conflict, future] {
            let plan = try fixtures.plan([forecast])
            #expect(plan.limits[0].outcome == .needsFreshReading)
            #expect(plan.hasUnknownUsage)
            #expect(plan.firstExhaustion == nil)
        }
        let fresh = try fixtures.plan([fixtures.forecast(age: 900)])
        #expect(try fixtures.projection(fresh.limits[0]).ratePerHour > 0)
    }

    @Test func sparseActivityDoesNotBecomeASafeProjection() throws {
        for offsets: [Double] in [[0], [9, 4, 0], [60, 40, 0]] {
            let history = offsets.map { minutes in
                Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: 40 - minutes / 6,
                        resetsAt: fixtures.now.addingTimeInterval(86400),
                        at: fixtures.now.addingTimeInterval(-minutes * 60))
            }
            let forecast = try #require(ForecastEngine.forecast(for: history, now: fixtures.now))
            let plan = try fixtures.plan([forecast])
            #expect(plan.limits[0].outcome == .needsActivity)
            #expect(plan.hasUnknownUsage)
        }
    }

    @Test func quietUsageRemainsUnknownWhenPlanningMoreWork() throws {
        let plan = try fixtures.plan([fixtures.forecast(rate: 0)])
        #expect(plan.limits[0].outcome == .inactive)
        #expect(plan.hasUnknownUsage)
        #expect(plan.firstExhaustion == nil)
    }

    @Test func aKnownExhaustedLimitRemainsOutWithoutFreshActivity() throws {
        let forecast = try fixtures.forecast(used: 100, rate: 0, age: 6 * 3600)
        let plan = try fixtures.plan([forecast])
        #expect(plan.limits[0].outcome == .exhausted)
        #expect(plan.firstExhaustion?.id == forecast.key)
        #expect(plan.exhaustionTime(plan.limits[0]) == fixtures.now)
        #expect(!plan.hasUnknownUsage)
        let resetting = try fixtures.plan([fixtures.forecast(used: 100, rate: 0, resetIn: 1800)])
        #expect(resetting.hasUnknownUsage)
    }

    @Test func anExpiredWindowWaitsForTheNewReading() throws {
        let plan = try fixtures.plan([fixtures.forecast(resetIn: -1)])
        #expect(plan.limits[0].outcome == .reset)
        #expect(plan.hasUnknownUsage)
        #expect(plan.firstExhaustion == nil)
    }

    @Test func exhaustionAtSessionEndCountsButExhaustionAtResetDoesNot() throws {
        let forecast = try fixtures.forecast(used: 80, rate: 10)
        let end = try fixtures.plan([forecast])
        #expect(end.exhaustionTime(end.limits[0]) == end.endsAt)
        let shorter = try fixtures.plan([forecast], minutes: 119)
        #expect(shorter.firstExhaustion == nil)
        #expect(try fixtures.projection(shorter.limits[0]).usedPercent < 100)
        let reset = try fixtures.plan([fixtures.forecast(used: 80, rate: 10, resetIn: 7200)])
        #expect(reset.firstExhaustion == nil)
        #expect(try fixtures.projection(reset.limits[0]).usedPercent == 100)
        #expect(reset.hasUnknownUsage)
    }

    @Test func usesTheActiveSessionInsteadOfTheDailyAverage() throws {
        let forecast = try fixtures.forecast(used: 50, rate: 10)
        let old = Reading(provider: forecast.key.provider, limit: forecast.key.limit, windowMinutes: 10080,
                          usedPercent: 0, resetsAt: forecast.resetsAt,
                          at: fixtures.now.addingTimeInterval(-86400))
        let combined = try #require(ForecastEngine.forecast(for: [old] + forecast.history, now: fixtures.now))
        #expect(try #require(combined.ratePerHour) < 3)
        let plan = try fixtures.plan([combined])
        #expect(try fixtures.projection(plan.limits[0]).ratePerHour == 10)
        #expect(try fixtures.projection(plan.limits[0]).usedPercent == 70)
    }

    @Test func boundsTheScenarioAndDoesNotTreatMissingLimitsAsSafe() throws {
        let forecast = try fixtures.forecast()
        for minutes in [-1, 0, 241, Int.max] {
            #expect(SessionPlan(forecasts: [forecast], minutes: minutes, now: fixtures.now) == nil)
        }
        #expect(try fixtures.plan([], minutes: 240).hasUnknownUsage)
        let partial = try fixtures.plan([forecast, fixtures.forecast(rate: 0, minutes: 300)])
        #expect(partial.hasUnknownUsage)
        #expect(partial.firstExhaustion == nil)
    }
}
