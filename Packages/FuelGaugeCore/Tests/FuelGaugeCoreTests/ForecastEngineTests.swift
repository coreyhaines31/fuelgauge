import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastEngineTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// A 5-hour window reset `resetsIn` hours from now, read at `minutesAgo` with `used` percent.
    func reading(_ used: Double, minutesAgo: Double, resetsIn: Double = 3, minutes: Int? = 300) -> Reading {
        Reading(
            provider: .claude, limit: "five_hour", windowMinutes: minutes, usedPercent: used,
            resetsAt: now.addingTimeInterval(resetsIn * 3600), at: now.addingTimeInterval(-minutesAgo * 60)
        )
    }

    @Test func learnsUntilTenMinutesOfReadings() throws {
        // The window began 2 hours ago, so its zero point is outside the 1-hour stretch.
        let readings = [reading(20, minutesAgo: 5), reading(21, minutesAgo: 0)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        #expect(forecast.verdict == .learning)
        #expect(forecast.ratePerHour == nil)
    }

    @Test func runsOutBeforeReset() throws {
        // 40% → 70% over the last hour: 30 points an hour, 30 left, reset in 3 hours.
        let readings = [reading(40, minutesAgo: 70), reading(55, minutesAgo: 30), reading(70, minutesAgo: 0)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        let rate = try #require(forecast.ratePerHour)
        #expect(abs(rate - 30) < 0.01)
        guard case .runsOut(let at, let earliest, let latest) = forecast.verdict else {
            Issue.record("expected runsOut, got \(forecast.verdict)")
            return
        }
        #expect(abs(at.timeIntervalSince(now) - 3600) < 1)
        #expect(earliest <= at)
        #expect(latest.map { $0 >= at } ?? true)
        #expect(abs((forecast.budgetPerHour ?? 0) - 10) < 0.01)
        #expect(forecast.isShort)
    }

    @Test func makesItAtASteadyPace() throws {
        let readings = [reading(10, minutesAgo: 60), reading(15, minutesAgo: 0)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        #expect(forecast.verdict == .makesIt(projectedPercent: 30))
        #expect(!forecast.isShort)
    }

    @Test func burstsCountAsBurnNotNoise() throws {
        // Flat, then a jump, then flat: the hour's climb is the burn rate.
        let readings = [10, 10, 10, 22, 22, 22].enumerated().map { index, used in
            reading(used, minutesAgo: Double(60 - index * 12))
        }
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        let rate = try #require(forecast.ratePerHour)
        #expect(rate > 10)
    }

    @Test func oneOldReadingIsNotAPace() throws {
        let forecast = try #require(ForecastEngine.forecast(for: [reading(89, minutesAgo: 30, resetsIn: 30)], now: now))
        #expect(forecast.verdict == .learning)
    }

    @Test func oneReadingFromBeforeTheStretchIsNotAPace() throws {
        let monthly = [reading(80, minutesAgo: 25 * 60, resetsIn: 24, minutes: nil)]
        #expect(try #require(ForecastEngine.forecast(for: monthly, now: now)).verdict == .learning)
    }

    @Test func aSlowClimbStillRunsOut() throws {
        let monthly = [
            reading(99.78, minutesAgo: 24 * 60, resetsIn: 48, minutes: nil),
            reading(99.9, minutesAgo: 0, resetsIn: 48, minutes: nil)
        ]
        guard case .runsOut = try #require(ForecastEngine.forecast(for: monthly, now: now)).verdict else {
            Issue.record("expected runsOut")
            return
        }
    }

    @Test func aFreshWeeklyWindowWaitsForThreeHours() throws {
        // A weekly window that began an hour ago with 1% used: too little to project across a week.
        let weekly = [reading(1, minutesAgo: 5, resetsIn: 7 * 24 - 1, minutes: 10080)]
        let early = try #require(ForecastEngine.forecast(for: weekly, now: now))
        #expect(early.verdict == .learning)
        let later = [reading(3, minutesAgo: 5, resetsIn: 7 * 24 - 4, minutes: 10080)]
        let forecast = try #require(ForecastEngine.forecast(for: later, now: now))
        #expect(forecast.ratePerHour != nil)
    }

    @Test func aFreshWeeklyWindowUsesADailyAverage() throws {
        // A weekly window that opened 3 hours ago, already at 9% from one heavy burst. Spread over the day,
        // that's about 0.4% an hour, which lasts the week; projected as-is it would "run out" in days.
        let weekly = [
            reading(3, minutesAgo: 170, resetsIn: 7 * 24 - 3, minutes: 10080),
            reading(9, minutesAgo: 5, resetsIn: 7 * 24 - 3, minutes: 10080)
        ]
        let forecast = try #require(ForecastEngine.forecast(for: weekly, now: now))
        let rate = try #require(forecast.ratePerHour)
        #expect(abs(rate - 9.0 / 24) < 0.01)
        guard case .makesIt = forecast.verdict else {
            Issue.record("expected makesIt, got \(forecast.verdict)")
            return
        }
    }

    @Test func idleTimeSlowsThePace() throws {
        // All the climbing happened 50 minutes ago; since then nothing.
        let readings = [reading(10, minutesAgo: 60), reading(30, minutesAgo: 50)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        let rate = try #require(forecast.ratePerHour)
        #expect(abs(rate - 20) < 0.01)
    }

    @Test func aWindowThatStartedRecentlyCountsFromZero() throws {
        // Reset in 4h 40m means this 5-hour window began 20 minutes ago at 0%.
        let readings = [reading(5, minutesAgo: 5, resetsIn: 4 + 40.0 / 60)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        let rate = try #require(forecast.ratePerHour)
        #expect(abs(rate - 15) < 0.01)
    }

    @Test func ignoresReadingsFromThePreviousWindow() throws {
        let old = Reading(
            provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: 95,
            resetsAt: now.addingTimeInterval(-3600), at: now.addingTimeInterval(-7200)
        )
        let readings = [old, reading(4, minutesAgo: 0, resetsIn: 4.5)]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        #expect(forecast.history.count == 1)
        #expect(forecast.usedPercent == 4)
    }

    @Test func limitReachedAndReset() throws {
        let full = try #require(ForecastEngine.forecast(for: [reading(100, minutesAgo: 1)], now: now))
        #expect(full.verdict == .limitReached)
        let past = try #require(ForecastEngine.forecast(for: [reading(80, minutesAgo: 30, resetsIn: -0.1)], now: now))
        #expect(past.verdict == .reset)
    }

    @Test func monthlyLimitsUseADayOfHistory() {
        #expect(ForecastEngine.lookback(windowMinutes: nil) == 24 * 3600)
        #expect(ForecastEngine.lookback(windowMinutes: 300) == 3600)
        #expect(ForecastEngine.lookback(windowMinutes: 10080) == 24 * 3600)
    }

    @Test func groupsByLimit() {
        let weekly = Reading(
            provider: .codex, limit: "codex-10080", windowMinutes: 10080, usedPercent: 9,
            resetsAt: now.addingTimeInterval(86400), at: now
        )
        let forecasts = ForecastEngine.forecasts(from: [reading(10, minutesAgo: 0), weekly], now: now)
        #expect(forecasts.map(\.key.provider) == [.claude, .codex])
    }
}

@Suite struct ForecastTextTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
        return calendar
    }

    @Test func formatsTimesLikeAClock() throws {
        let now = try Date("2026-10-20T17:00:00Z", strategy: .iso8601) // Tue 10:00a PT
        #expect(ForecastText.time(now.addingTimeInterval(5 * 3600 + 40 * 60), now: now, calendar: calendar) == "3:40p")
        #expect(ForecastText.time(now.addingTimeInterval(3 * 86400 - 3600), now: now, calendar: calendar) == "Fri 9a")
        #expect(ForecastText.time(now.addingTimeInterval(20 * 86400), now: now, calendar: calendar) == "Nov 9")
    }

    @Test func formatsDurations() {
        #expect(ForecastText.duration(45 * 60) == "45m")
        #expect(ForecastText.duration(3 * 3600 + 7 * 60) == "3h 7m")
        #expect(ForecastText.duration(2 * 86400 + 16 * 3600) == "2d 16h")
    }

    @Test func nearTheResetItSaysWhatsLeftInsteadOfAnHourlyBudget() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let readings = [
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: 10,
                    resetsAt: now.addingTimeInterval(45 * 60), at: now.addingTimeInterval(-3600)),
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: 12,
                    resetsAt: now.addingTimeInterval(45 * 60), at: now)
        ]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        #expect(ForecastText.pace(forecast, now: now) == "Using 2.0% an hour. 88% left for the 45m until the reset.")
    }

    @Test func aBudgetTooSmallToShowSaysWhatsLeft() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let readings = [
            Reading(provider: .grokBot, limit: "weekly", windowMinutes: 10080, usedPercent: 97,
                    resetsAt: now.addingTimeInterval(32 * 3600), at: now.addingTimeInterval(-6 * 3600)),
            Reading(provider: .grokBot, limit: "weekly", windowMinutes: 10080, usedPercent: 99,
                    resetsAt: now.addingTimeInterval(32 * 3600), at: now)
        ]
        let forecast = try #require(ForecastEngine.forecast(for: readings, now: now))
        #expect(ForecastText.pace(forecast, now: now)?.hasSuffix("Only 1% left until the reset.") == true)
    }

    @Test func formatsPercents() {
        #expect(ForecastText.percent(0.4) == "<1%")
        #expect(ForecastText.percent(23.5) == "24%")
        #expect(ForecastText.shortName(300) == "5h")
        #expect(ForecastText.shortName(10080) == "wk")
    }
}

@Suite struct PanelTextTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func reading(_ used: Double, minutesAgo: Double, provider: Provider = .claude, limit: String = "five_hour",
                 minutes: Int? = 300, resetsIn: Double = 3) -> Reading {
        Reading(provider: provider, limit: limit, windowMinutes: minutes, usedPercent: used,
                resetsAt: now.addingTimeInterval(resetsIn * 3600), at: now.addingTimeInterval(-minutesAgo * 60))
    }

    @Test func summaryNamesTheLimitThatRunsOutFirst() {
        let forecasts = ForecastEngine.forecasts(from: [
            reading(40, minutesAgo: 60), reading(70, minutesAgo: 0),
            reading(10, minutesAgo: 60, provider: .codex, limit: "codex-10080", minutes: 10080, resetsIn: 100),
            reading(10, minutesAgo: 0, provider: .codex, limit: "codex-10080", minutes: 10080, resetsIn: 100)
        ], now: now)
        #expect(ForecastText.summary(forecasts, now: now).hasPrefix("Claude Code runs out"))
    }

    @Test func summaryWhenAllIsWell() {
        let readings = [reading(10, minutesAgo: 60), reading(11, minutesAgo: 0)]
        let forecasts = ForecastEngine.forecasts(from: readings, now: now)
        #expect(ForecastText.summary(forecasts, now: now) == "Everything makes it to reset")
        #expect(ForecastText.summary([], now: now) == "No readings yet")
    }

    @Test func learningCountsDownToTheForecast() throws {
        // A weekly window with readings that began an hour ago needs 3 hours: 2 hours to go.
        let weekly = [reading(30, minutesAgo: 60, limit: "seven_day", minutes: 10080, resetsIn: 50),
                      reading(31, minutesAgo: 0, limit: "seven_day", minutes: 10080, resetsIn: 50)]
        let forecast = try #require(ForecastEngine.forecast(for: weekly, now: now))
        #expect(ForecastText.learning(forecast, now: now) == "Forecast in about 2h")
    }

    @Test func chartsZoomToTheRecentStretch() throws {
        let weekly = [reading(30, minutesAgo: 600, limit: "seven_day", minutes: 10080, resetsIn: 100),
                      reading(40, minutesAgo: 0, limit: "seven_day", minutes: 10080, resetsIn: 100)]
        let forecast = try #require(ForecastEngine.forecast(for: weekly, now: now))
        let range = ForecastEngine.chartRange(forecast, now: now)
        #expect(range.lowerBound == now.addingTimeInterval(-24 * 3600))
        #expect(range.upperBound <= forecast.resetsAt)
    }
}
