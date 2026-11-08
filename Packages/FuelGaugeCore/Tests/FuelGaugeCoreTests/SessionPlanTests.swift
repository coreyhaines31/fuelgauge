import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct SessionPlanTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func forecast(used: Double = 40, rate: Double = 10, minutes: Int = 10080,
                  resetIn: TimeInterval = 72 * 3600, age: TimeInterval = 0) throws -> Forecast {
        let data = [60.0, 30, 0].map { minutesAgo in
            Reading(provider: .codex, limit: "\(minutes)", windowMinutes: minutes,
                    usedPercent: used - rate * minutesAgo / 60, resetsAt: now.addingTimeInterval(resetIn),
                    at: now.addingTimeInterval(-minutesAgo * 60 - age))
        }
        return try #require(ForecastEngine.forecast(for: data, now: now))
    }

    func plan(_ forecasts: [Forecast], minutes: Int = 120) throws -> SessionPlan {
        try #require(SessionPlan(forecasts: forecasts, minutes: minutes, now: now))
    }

    func projection(_ limit: SessionPlan.Limit) throws -> SessionPlan.Projection {
        guard case .projected(let projection) = limit.outcome else {
            throw NSError(domain: "Expected a session projection", code: 1)
        }
        return projection
    }

    @Test func projectsActivePaceEvenWhileTheWeeklyForecastIsLearning() throws {
        let forecast = try forecast()
        #expect(forecast.verdict == .learning)
        let plan = try plan([forecast])
        let result = try projection(plan.limits[0])
        #expect(result.ratePerHour == 10)
        #expect(result.usedPercent == 60)
        #expect(result.until == now.addingTimeInterval(7200))
        #expect(result.runsOutAt == nil)
        #expect(!plan.hasUnknownUsage)
        #expect(plan.firstExhaustion == nil)
    }

    @Test func findsTheFirstConstraintAcrossShortAndWeeklyLimits() throws {
        let weekly = try forecast(used: 95, rate: 10)
        let short = try forecast(used: 40, rate: 40, minutes: 300, resetIn: 4 * 3600)
        let plan = try plan([short, weekly])
        let first = try #require(plan.firstExhaustion)
        #expect(first.id == weekly.key)
        #expect(plan.exhaustionTime(first) == now.addingTimeInterval(1800))
        #expect(try projection(plan.limits[0]).usedPercent == 100)
        #expect(try projection(plan.limits[1]).usedPercent == 100)
    }

    @Test func stopsAtResetWithoutPredictingUsageInANewWindow() throws {
        let forecast = try forecast(used: 40, rate: 10, resetIn: 1800)
        let plan = try plan([forecast])
        let result = try projection(plan.limits[0])
        #expect(result.usedPercent == 45)
        #expect(result.until == forecast.resetsAt)
        #expect(result.stopsAtReset)
        #expect(result.runsOutAt == nil)
        #expect(plan.hasUnknownUsage)
    }
}
