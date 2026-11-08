import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ScheduleProfileTests {
    let fixtures = UsageScheduleTests()

    @Test func showsTheSameHourlyRatesTheForecastUsesIncludingQuietHours() throws {
        let data = fixtures.intervals()
        let schedule = try #require(UsageSchedule(data, now: data.last!.end, calendar: .utc))
        let profile = schedule.profile
        #expect(profile.hours.count == 48)
        #expect(Set(profile.hours.map(\.id)).count == 48)
        for hour in profile.hours {
            let offset = hour.hour + (hour.day == .weekend ? 5 * 24 : 0)
            let date = fixtures.start.addingTimeInterval(Double(offset) * 3600)
            #expect(hour.ratePerHour == schedule.rate(at: date))
            #expect(hour.source == .observed)
            #expect(hour.observedDates >= 2)
            #expect(hour.observedHours >= 2)
        }
        #expect(profile.hours.first(where: { $0.day == .weekday && $0.hour == 10 })?.ratePerHour == 2)
        #expect(profile.hours.first(where: { $0.day == .weekday && $0.hour == 22 })?.ratePerHour == 0)
        #expect(profile.hours.filter { $0.day == .weekend }.allSatisfy { $0.ratePerHour == 0 })
    }

    @Test func distinguishesPooledFallbackFromUnknownHoursAndPartialEvidence() throws {
        let data = fixtures.intervals().filter { $0.consumed > 0 }
        let schedule = UsageSchedule(observing: data, now: data.last!.end, calendar: .utc)
        let profile = schedule.profile
        let weekend = try #require(profile.hours.first { $0.day == .weekend && $0.hour == 10 })
        #expect(weekend.source == .pooled)
        #expect(weekend.ratePerHour == 2)
        #expect(weekend.observedDates == 15)
        let night = try #require(profile.hours.first { $0.day == .weekday && $0.hour == 22 })
        #expect(night.source == .unknown)
        #expect(night.ratePerHour == nil)
        #expect(profile.recentActivity == nil)
        let oneHour = UsageSchedule(observing: [data[0]], now: data[0].end, calendar: .utc).profile
        let partial = try #require(oneHour.hours.first { $0.day == .weekday && $0.hour == 9 })
        #expect(partial.observedDates == 1)
        #expect(partial.observedHours == 1)
        #expect(partial.ratePerHour == nil)
    }

    @Test func separatesMeasuredActivityFromTheCappedForecastAdjustment() throws {
        let data = fixtures.intervals(recentRate: 60)
        let schedule = try #require(UsageSchedule(data, now: data.last!.end, calendar: .utc))
        let activity = try #require(schedule.profile.recentActivity)
        #expect(try #require(activity.ratio) > 2)
        #expect(activity.multiplier == 2)
        #expect(schedule.recentMultiplier == activity.multiplier)
        #expect(activity.observedHours == 72)
        let quiet = data.map { ReadingTimeline.Interval(start: $0.start, end: $0.end, consumed: 0) }
        let noBaseline = try #require(UsageSchedule(quiet, now: quiet.last!.end, calendar: .utc))
        #expect(noBaseline.profile.recentActivity?.ratio == nil)
        #expect(noBaseline.recentMultiplier == 1)
        let insufficient = ScheduleProfile.Activity(observedHours: 11, actualUsage: 30, expectedUsage: 10)
        #expect(insufficient.ratio == nil)
    }

    @Test func dailyForecastsExposeTheProfileButShortWindowsDoNot() throws {
        let fixtures = ForecastJournalTests()
        let weekly = try #require(ForecastEngine.forecast(for: fixtures.history, now: fixtures.now, calendar: .utc))
        #expect(weekly.scheduleProfile?.hours.count == 48)
        let short = fixtures.history.map {
            Reading(provider: $0.provider, limit: "short", windowMinutes: 300, usedPercent: $0.usedPercent,
                    resetsAt: fixtures.now.addingTimeInterval(3600), at: $0.at)
        }
        let forecast = try #require(ForecastEngine.forecast(for: short, now: fixtures.now, calendar: .utc))
        #expect(forecast.scheduleProfile == nil)
    }
}
