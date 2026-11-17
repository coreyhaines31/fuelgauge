import Foundation
@testable import FuelGaugeCore
import Testing

struct ClaudeUsageTests {
    private func sample() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "Samples/claude-get-usage", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test func readsFableAllowanceAndItsShareOfTheWeek() throws {
        let now = Date(timeIntervalSince1970: 1_795_000_000)
        let usage = try #require(ClaudeUsage.decode(try sample(), at: now))
        let fable = try #require(usage.model(named: "fable"))
        #expect(fable.name == "Fable")
        #expect(fable.usedPercent == 36)
        #expect(fable.usedPercentOfWeekly == 18)
        #expect(fable.allowancePercentOfWeekly == 50)
        #expect(fable.resetsAt == Date(timeIntervalSince1970: 1_795_208_400))
        let reading = try #require(usage.readings().first)
        #expect(reading.limit == "seven_day_model_fable")
        #expect(reading.windowMinutes == 10080)
        #expect(reading.at == now)
    }

    @Test func noPlanLimitsIsNil() {
        #expect(ClaudeUsage.decode(Data(#"{"rate_limits":null}"#.utf8)) == nil)
        #expect(ClaudeUsage.decode(Data("[]".utf8)) == nil)
        #expect(ClaudeUsage.decode(Data("not json".utf8)) == nil)
    }

    @Test func noModelRowsIsEmptyNotZero() throws {
        let json = #"{"rate_limits":{"limits":[{"kind":"weekly_all","percent":10,"#
            + #""resets_at":"2026-11-20T21:00:00Z"}]}}"#
        let usage = try #require(ClaudeUsage.decode(Data(json.utf8)))
        #expect(usage.models.isEmpty)
        #expect(usage.readings().isEmpty)
    }

    @Test func malformedRowsAreSkipped() throws {
        let json = #"""
        {"rate_limits":{"limits":[
          {"kind":"weekly_scoped","percent":"36","resets_at":"2026-11-20T21:00:00Z",
           "scope":{"model":{"display_name":"A"}}},
          {"kind":"weekly_scoped","percent":true,"resets_at":"2026-11-20T21:00:00Z",
           "scope":{"model":{"display_name":"B"}}},
          {"kind":"weekly_scoped","percent":12,"resets_at":"soon","scope":{"model":{"display_name":"C"}}},
          {"kind":"weekly_scoped","percent":12,"resets_at":"2026-11-20T21:00:00Z",
           "scope":{"model":{"display_name":" "}}},
          {"kind":"weekly_scoped","percent":12,"resets_at":1795208400,"scope":{"model":{"display_name":"Fable"}}}
        ],"weekly_scoped_shares":[{"limit_index":0,"used_percent_of_weekly":99}]}}
        """#
        let usage = try #require(ClaudeUsage.decode(Data(json.utf8)))
        #expect(usage.models.map(\.name) == ["Fable"])
        // The share belongs to row 0, which was skipped, so Fable has none.
        #expect(usage.models.first?.usedPercentOfWeekly == nil)
    }

    @Test func fallsBackToModelScopedRows() throws {
        let json = #"{"rate_limits":{"model_scoped":[{"display_name":"Fable","utilization":40,"#
            + #""resets_at":"2026-11-20T21:00:00Z"}]}}"#
        let usage = try #require(ClaudeUsage.decode(Data(json.utf8)))
        #expect(usage.models.first?.usedPercent == 40)
        #expect(usage.models.first?.usedPercentOfWeekly == nil)
    }

    @Test func modelLimitNames() {
        #expect(ModelLimit.limit(forModel: "Fable") == "seven_day_model_fable")
        #expect(ModelLimit.limit(forModel: "Big Model") == "seven_day_model_big_model")
        #expect(ModelLimit.modelName(of: "seven_day_model_fable") == "Fable")
        #expect(ModelLimit.modelName(of: "seven_day_model_big_model") == "Big Model")
        #expect(ModelLimit.modelName(of: "seven_day") == nil)
        #expect(ModelLimit.limit(forModel: String(repeating: "x", count: 60)).count <= 40)
    }
}
