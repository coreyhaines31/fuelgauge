import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ClaudeStatusLineTests {
    @Test func readsFiveHourAndWeeklyWindows() throws {
        let now = Date(timeIntervalSince1970: 1_738_420_000)
        let readings = ClaudeStatusLine.readings(from: try Data(contentsOf: try sample("statusline.json")), at: now)
        #expect(readings.map(\.limit) == ["five_hour", "seven_day"])
        #expect(readings.map(\.windowMinutes) == [300, 10080])
        #expect(readings[0].usedPercent == 23.5)
        #expect(readings[0].at == now)
    }

    @Test func tagsReadingsWithTheSessionsAccount() throws {
        let input = try Data(contentsOf: try sample("statusline.json"))
        #expect(ClaudeStatusLine.readings(from: input).allSatisfy { $0.account == nil })
        let work = ClaudeStatusLine.readings(from: input, account: "work_1a2b3c")
        #expect(work.map(\.key.id) == ["claude@work_1a2b3c/five_hour", "claude@work_1a2b3c/seven_day"])
    }

    @Test func noLimitsBeforeTheFirstReply() {
        #expect(ClaudeStatusLine.readings(from: Data(#"{"model":{"id":"x"}}"#.utf8)).isEmpty)
        #expect(ClaudeStatusLine.readings(from: Data("not json".utf8)).isEmpty)
    }
}
