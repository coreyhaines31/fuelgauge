import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct CursorReaderTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func readsTheMonthlyPlan() throws {
        let json = #"""
        {"billingCycleStart":"2026-10-01T00:00:00.000Z","billingCycleEnd":"2026-11-01T00:00:00.000Z",
         "membershipType":"premium","isUnlimited":false,
         "individualUsage":{"plan":{"enabled":true,"used":1154,"limit":4615,"remaining":3461,
           "autoPercentUsed":20,"apiPercentUsed":5,"totalPercentUsed":25},"onDemand":{"enabled":false,"used":0}}}
        """#
        let readings = CursorReader.readings(from: Data(json.utf8), at: now)
        #expect(readings.count == 1)
        #expect(readings.first?.usedPercent == 25)
        #expect(readings.first?.windowMinutes == nil)
        #expect(readings.first?.resetsAt == (try? Date("2026-11-01T00:00:00Z", strategy: .iso8601)))
    }

    @Test func nothingForUnlimitedPlans() {
        let json = #"{"billingCycleEnd":"2026-11-01T00:00:00.000Z","isUnlimited":true}"#
        #expect(CursorReader.readings(from: Data(json.utf8), at: now).isEmpty)
    }

    @Test func findsTheUserInTheToken() {
        // {"sub":"github|user_01ABC"} as a JWT payload.
        let payload = Data(#"{"sub":"github|user_01ABC"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        #expect(CursorReader.userID(fromJWT: "header.\(payload).signature") == "user_01ABC")
    }
}
