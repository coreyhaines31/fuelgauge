import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct AdaptiveForecastTests {
    @Test func doesNotProjectFridayWorkThroughAQuietWeekend() throws {
        let now = ForecastSamples.start.addingTimeInterval((25 * 24 + 17) * 3600)
        let data = ForecastSamples.weekdays(until: now)
        let old = try #require(ForecastEngine.forecast(for: data, now: now, method: .recent))
        #expect(old.isShort)
        let forecast = try #require(ForecastEngine.forecast(for: data, now: now, method: .adaptive, calendar: .utc))
        #expect(forecast.basis == .schedule)
        guard case .makesIt(let used) = forecast.verdict else { Issue.record("Expected to last the weekend"); return }
        #expect(used < 95)
        let sunday = forecast.projection.filter {
            Calendar.utc.component(.weekday, from: $0.at) == 1
        }
        #expect((sunday.last!.usedPercent - sunday.first!.usedPercent) < 0.01)
    }

    @Test func warnsWhenTheCurrentSessionWouldExhaustAnOtherwiseSufficientBudget() throws {
        let now = ForecastSamples.start.addingTimeInterval((28 * 24 + 10) * 3600)
        let data = ForecastSamples.weekdays(until: now, mondayRate: 5)
        let forecast = try #require(ForecastEngine.forecast(for: data, now: now, method: .adaptive, calendar: .utc))
        let session = try #require(forecast.sessionRunsOutAt)
        #expect(abs(session.timeIntervalSince(now) - 5 * 3600) < 1)
        #expect(forecast.basis == .schedule)
    }

    @Test func staleAndConflictingReadingsCannotClaimThatLimitsWillLast() throws {
        let now = ForecastSamples.start.addingTimeInterval((25 * 24 + 17) * 3600)
        let data = ForecastSamples.weekdays(until: now)
        let stale = try #require(ForecastEngine.forecast(for: data, now: now.addingTimeInterval(7 * 3600),
                                                       method: .adaptive))
        #expect(stale.verdict == .stale)
        var lower = data.last!
        lower.at = now.addingTimeInterval(60)
        lower.usedPercent -= 5
        let conflict = try #require(ForecastEngine.forecast(for: data + [lower], now: lower.at, method: .adaptive))
        #expect(conflict.verdict == .stale)
        #expect(!ForecastText.summary([stale, conflict], now: now).contains("makes it"))
        let planner = AlertPlanner(settings: .init(alertWhenShort: true, thresholds: [50]))
        #expect(planner.plan([conflict], state: .init(), now: lower.at).0.isEmpty)
    }

    @Test func futureHistoryCannotChangeTheForecast() throws {
        let now = ForecastSamples.start.addingTimeInterval((25 * 24 + 17) * 3600)
        let past = ForecastSamples.weekdays(until: now)
        let future = ForecastSamples.weekdays(until: now.addingTimeInterval(3 * 86400), mondayRate: 20)
        let expected = ForecastEngine.forecast(for: past, now: now, method: .adaptive, calendar: .utc)
        #expect(expected == ForecastEngine.forecast(for: future, now: now, method: .adaptive, calendar: .utc))
    }

    @Test func aCorrectionDoesNotInferAZeroAtTheScheduledWindowStart() throws {
        let now = ForecastSamples.start.addingTimeInterval(4 * 3600)
        let readings = [(0.0, 80.0), (3.5, 2), (3.75, 2), (4.0, 2)].map { hour, used in
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: used,
                    resetsAt: ForecastSamples.start.addingTimeInterval(5 * 3600),
                    at: ForecastSamples.start.addingTimeInterval(hour * 3600))
        }
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now, method: .adaptive))
        #expect(forecast.ratePerHour == 0)
        #expect(forecast.history.count == 2)
    }
}
