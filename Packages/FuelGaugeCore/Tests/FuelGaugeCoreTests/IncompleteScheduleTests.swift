import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct IncompleteScheduleTests {
    let start = ForecastSamples.start
    var now: Date { start.addingTimeInterval(21 * 86400) }

    func daytimeReadings() -> [Reading] {
        (0..<21).flatMap { day in
            (9...21).map { hour in
                let at = start.addingTimeInterval(Double(day * 24 + hour) * 3600)
                // Overnight consumption is observed, but its timing is unknown across the 12-hour gap.
                let used = Double(day % 7) * 12 + 6 + Double(hour - 9) * 0.5
                return Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: used,
                               resetsAt: start.addingTimeInterval(Double(day / 7 + 1) * 7 * 86400), at: at)
            }
        }
    }

    @Test func aFreshWindowDoesNotTreatUnobservedHoursAsZeroConsumption() throws {
        let latest = Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: 50,
                             resetsAt: now.addingTimeInterval(7 * 86400), at: now)
        let data = daytimeReadings() + [latest]
        #expect(UsageSchedule(ReadingTimeline(data, now: now).intervals, now: now, calendar: .utc) != nil)
        let forecast = try #require(ForecastEngine.forecast(for: data, now: now, calendar: .utc))
        #expect(forecast.ratePerHour == nil)
        #expect(forecast.verdict == .learning)
        let pointCount = forecast.projection.count
        #expect(pointCount == 0)
    }

    @Test func aCompleteScheduleStillForecastsWithoutACurrentPace() throws {
        let data = ForecastSamples.weekdays(until: now)
        let forecast = try #require(ForecastEngine.forecast(for: data, now: now, calendar: .utc))
        #expect(forecast.ratePerHour == nil)
        #expect(forecast.basis == .schedule)
        #expect(!forecast.projection.isEmpty)
    }

    @Test func anIncompleteScheduleCanUseAKnownRecentPace() throws {
        let fresh = [0.0, 3.0].map { hours in
            Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: 50 + hours,
                    resetsAt: now.addingTimeInterval(7 * 86400), at: now.addingTimeInterval(hours * 3600))
        }
        let forecast = try #require(ForecastEngine.forecast(for: daytimeReadings() + fresh,
                                                           now: fresh.last!.at, calendar: .utc))
        #expect(forecast.ratePerHour != nil)
        #expect(forecast.basis == .schedule)
        let next = try #require(forecast.projection.dropFirst().first)
        #expect(next.usedPercent > forecast.usedPercent)
    }

    @Test func unsupportedHoursDoNotInflateTheTrendForKnownHours() throws {
        var intervals = ReadingTimeline(daytimeReadings(), now: now).intervals
        let overnight = now.addingTimeInterval(-19 * 3600)
        intervals.append(.init(start: overnight, end: overnight.addingTimeInterval(3600), consumed: 10))
        intervals.sort { $0.start < $1.start }
        let schedule = try #require(UsageSchedule(intervals, now: now, calendar: .utc))
        #expect(abs(schedule.recentMultiplier - 1) < 0.001)
    }
}
