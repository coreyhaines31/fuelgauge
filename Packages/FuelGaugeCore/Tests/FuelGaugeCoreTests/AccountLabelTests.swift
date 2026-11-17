import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct AccountLabelTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let home = temporaryFolder()

    private func readings(used: Double, account: String?) -> [Reading] {
        let resetsAt = now.addingTimeInterval(3 * 3600)
        return [used - 30, used].enumerated().map { index, percent in
            Reading(provider: .claude, limit: "five_hour", windowMinutes: 300, usedPercent: percent,
                    resetsAt: resetsAt, at: now.addingTimeInterval(Double(index - 1) * 3600), account: account)
        }
    }

    @Test func oneAccountPerToolReadsAsBefore() throws {
        let list = AccountList.load(from: temporaryDefaults(), environment: [:], home: home)
        let forecast = try #require(list.label(ForecastEngine.forecasts(from: readings(used: 85, account: nil),
                                                                        now: now)).first)
        #expect(forecast.accountName == nil)
        #expect(forecast.limitPhrase == "Claude Code's 5-hour limit")
        #expect(forecast.sourceLabel == "Claude Code")
        let json = String(bytes: try ForecastJSON.encode([forecast], now: now), encoding: .utf8) ?? ""
        #expect(!json.contains("account"))
    }

    @Test func severalAccountsAreNamedInLabelsAlertsAndJSON() throws {
        var list = AccountList.load(from: temporaryDefaults(), environment: [:], home: home)
        let work = Account.make(.claude, folder: "~/.claude-work", home: home)
        list.add(work)
        let forecasts = list.label(ForecastEngine.forecasts(
            from: readings(used: 85, account: nil) + readings(used: 82, account: work.slug), now: now))
        #expect(forecasts.map(\.accountName) == ["Main", "Work"])
        let workForecast = try #require(forecasts.first { $0.key.account == work.slug })
        #expect(workForecast.sourceLabel == "Claude Code · Work")
        #expect(ForecastText.summary([workForecast], now: now).hasPrefix("Work's Claude Code runs out"))

        let planner = AlertPlanner(settings: .init(alertWhenShort: false, thresholds: [80]))
        let (alerts, _) = planner.plan(forecasts, state: .init(), now: now)
        #expect(alerts.map(\.title) == ["Main's Claude Code 5-hour limit is 85% used",
                                        "Work's Claude Code 5-hour limit is 82% used"])
        #expect(alerts.map(\.id) == ["claude/five_hour|80", "claude@\(work.slug!)/five_hour|80"])

        let json = try #require(try JSONSerialization.jsonObject(with: ForecastJSON.encode(forecasts, now: now))
            as? [[String: Any]])
        #expect(json.map { $0["account_name"] as? String } == ["Main", "Work"])
        #expect(json.map { $0["account"] as? String } == [nil, work.slug])
    }
}
