import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastBacktestTests {
    @Test func scheduleImprovesHeldOutWeekdayUsage() throws {
        let now = ForecastSamples.start.addingTimeInterval((28 * 24 + 17) * 3600)
        let data = ForecastSamples.weekdays(until: now).map { reading in
            var reading = reading
            if reading.at >= ForecastSamples.start.addingTimeInterval(21 * 86400) {
                reading.usedPercent = min(100, reading.usedPercent + 20)
            }
            return reading
        }
        let results = ForecastBacktest.run(data, since: ForecastSamples.start.addingTimeInterval(21 * 86400),
                                          now: now, calendar: .utc)
        let daily = try #require(results.first { $0.horizonHours == 24 })
        #expect(daily.pairedForecasts > 50)
        #expect(daily.scheduledForecasts == daily.pairedForecasts)
        #expect(try #require(daily.adaptiveMAE) < #require(daily.recentMAE))
        #expect(daily.adaptiveEarlyExhaustions < daily.recentEarlyExhaustions)
    }

    @Test func unknownOutcomesAndResetCrossingsAreNotScoredAsSuccesses() {
        let start = ForecastSamples.start
        let data = [0, 1, 2, 3, 20, 21, 22].map { hour in
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300,
                    usedPercent: Double(hour % 20),
                    resetsAt: start.addingTimeInterval(hour < 20 ? 5 * 3600 : 25 * 3600),
                    at: start.addingTimeInterval(Double(hour) * 3600))
        }
        let results = ForecastBacktest.run(data, since: start, now: start.addingTimeInterval(24 * 3600))
        #expect(results.filter { $0.horizonHours >= 6 }.allSatisfy { $0.eligible == 0 })
        #expect(results.first?.eligible == 5)
    }

    @Test func reportsAbstentionsInsteadOfHidingThemInAccuracy() throws {
        let start = ForecastSamples.start
        let data = [0, 1, 2, 3, 11, 12, 13].map { hour in
            Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: Double(10 + hour),
                    resetsAt: start.addingTimeInterval(7 * 86400), at: start.addingTimeInterval(Double(hour) * 3600))
        }
        let results = ForecastBacktest.run(data, since: start, now: start.addingTimeInterval(14 * 3600))
        let hourly = try #require(results.first)
        #expect(hourly.adaptiveForecasts < hourly.recentForecasts)
        #expect(hourly.pairedForecasts <= hourly.adaptiveForecasts)
    }

    @Test func predictionsUseOnlyHistoryAvailableAtTheReplayCheckpoint() throws {
        let start = ForecastSamples.start
        let now = start.addingTimeInterval(4 * 3600)
        let data = [0, 1, 2, 3, 4, 5].map { hour in
            Reading(provider: .codex, limit: "weekly", windowMinutes: 10080,
                    usedPercent: hour == 5 ? 90 : Double(hour), resetsAt: start.addingTimeInterval(7 * 86400),
                    at: start.addingTimeInterval(Double(hour) * 3600))
        }
        let full = ForecastBacktest.run(data, since: start, now: now)
        let truncated = ForecastBacktest.run(Array(data.dropLast()), since: start, now: now)
        #expect(full.first?.recentError == truncated.first?.recentError)
        #expect(full.first?.eligible == truncated.first?.eligible)
    }
}
