import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct StatusLineStripTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func readings(_ limit: String, minutes: Int, used: [Double], resetsIn: Double) -> [Reading] {
        used.enumerated().map { index, value in
            Reading(
                provider: .claude, limit: limit, windowMinutes: minutes, usedPercent: value,
                resetsAt: now.addingTimeInterval(resetsIn * 3600),
                at: now.addingTimeInterval(Double(index - used.count + 1) * 20 * 60)
            )
        }
    }

    @Test func putsTheShortWindowFirst() {
        let forecasts = ForecastEngine.forecasts(
            from: readings("seven_day", minutes: 10080, used: [41, 41, 41], resetsIn: 60)
                + readings("five_hour", minutes: 300, used: [30, 45, 60, 75], resetsIn: 3),
            now: now
        )
        let strip = StatusLineStrip.render(forecasts, now: now, color: false)
        #expect(strip?.hasPrefix("⛽ 5h 75% out ~") == true)
        #expect(strip?.hasSuffix(" · wk 41% ok") == true)
    }

    @Test func nothingToShowWithoutForecasts() {
        #expect(StatusLineStrip.render([], now: now) == nil)
    }

    @Test func colorsByVerdict() {
        let full = readings("five_hour", minutes: 300, used: [100], resetsIn: 1)
        let forecasts = ForecastEngine.forecasts(from: full, now: now)
        #expect(StatusLineStrip.render(forecasts, now: now)?.contains("\u{1B}[31m") == true)
    }
}

@Suite struct ForecastJSONTests {
    @Test func usesStableSnakeCaseKeys() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let reading = Reading(
            provider: .codex, limit: "codex-10080", windowMinutes: 10080, usedPercent: 100,
            resetsAt: now.addingTimeInterval(3600), at: now
        )
        let data = try ForecastJSON.encode(ForecastEngine.forecasts(from: [reading], now: now), now: now)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]]).first
        #expect(object?["tool"] as? String == "codex")
        #expect(object?["window"] as? String == "weekly")
        #expect(object?["verdict"] as? String == "out")
        #expect(object?["used_percent"] as? Double == 100)
        #expect(object?["resets_at"] is String)
    }
}
