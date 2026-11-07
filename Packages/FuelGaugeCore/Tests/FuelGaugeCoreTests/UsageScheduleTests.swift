import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct UsageScheduleTests {
    let start = Date(timeIntervalSince1970: 1_788_739_200) // Monday, September 7, 2026 UTC.
    var calendar: Calendar { .utc }

    func intervals(days: Int = 21, recentRate: Double = 2) -> [ReadingTimeline.Interval] {
        (0..<(days * 24)).map { hour in
            let at = start.addingTimeInterval(Double(hour) * 3600)
            let busy = !calendar.isDateInWeekend(at) && (9..<17).contains(calendar.component(.hour, from: at))
            let rate = hour >= (days - 3) * 24 ? recentRate : 2
            return ReadingTimeline.Interval(start: at, end: at.addingTimeInterval(3600), consumed: busy ? rate : 0)
        }
    }

    @Test func learnsNightsAndWeekendsInsteadOfAssumingThem() throws {
        let data = intervals()
        let now = try #require(data.last?.end)
        let schedule = try #require(UsageSchedule(data, now: now, calendar: calendar))
        #expect(schedule.rate(at: start.addingTimeInterval(10 * 3600), fallback: 1) == 2)
        #expect(schedule.rate(at: start.addingTimeInterval(22 * 3600), fallback: 1) == 0)
        #expect(schedule.rate(at: start.addingTimeInterval((5 * 24 + 10) * 3600), fallback: 1) == 0)
        let overnight = data.map { ReadingTimeline.Interval(start: $0.start, end: $0.end, consumed: 3) }
        let alwaysBusy = try #require(UsageSchedule(overnight, now: now, calendar: calendar))
        #expect(abs(alwaysBusy.rate(at: now, fallback: 0) - 3) < 0.001)
    }

    @Test func sparseAndShortHistoriesDoNotInventASchedule() {
        let short = intervals(days: 5)
        #expect(UsageSchedule(short, now: short.last!.end, calendar: calendar) == nil)
        let sparse = intervals().filter { $0.consumed > 0 }
        #expect(UsageSchedule(sparse, now: start.addingTimeInterval(21 * 86400), calendar: calendar) == nil)
    }

    @Test func respondsToRecentIntensityWithoutExtrapolatingAccelerationForever() throws {
        let data = intervals(recentRate: 6)
        let schedule = try #require(UsageSchedule(data, now: data.last!.end, calendar: calendar))
        #expect(schedule.recentMultiplier > 1)
        #expect(schedule.recentMultiplier <= 2)
    }

    @Test func usesTheProvidedLocalTimeZoneAcrossDaylightSaving() throws {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let beginning = try Date("2026-10-19T07:00:00Z", strategy: .iso8601)
        let data = (0..<(21 * 24 + 1)).map { hour in
            let at = beginning.addingTimeInterval(Double(hour) * 3600)
            return ReadingTimeline.Interval(start: at, end: at.addingTimeInterval(3600),
                                            consumed: local.component(.hour, from: at) == 9 ? 2 : 0)
        }
        let schedule = try #require(UsageSchedule(data, now: data.last!.end, calendar: local))
        let morning = try Date("2026-11-09T17:00:00Z", strategy: .iso8601)
        #expect(schedule.rate(at: morning, fallback: 1) == 2)
        #expect(schedule.rate(at: morning.addingTimeInterval(-3600), fallback: 1) == 0)
    }
}
