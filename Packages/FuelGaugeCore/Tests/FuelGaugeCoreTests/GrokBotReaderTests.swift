import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct GrokBotReaderTests {
    @Test func readsTheWeeklyUsageCache() throws {
        let readings = GrokBotReader(folder: try sample("grok")).read()
        #expect(readings.count == 1)
        #expect(abs(readings[0].usedPercent - 89.49) < 0.01)
        #expect(readings[0].windowMinutes == 10080)
        #expect(readings[0].resetsAt == Date(timeIntervalSince1970: 1_792_645_516.371))
        #expect(readings[0].at == Date(timeIntervalSince1970: 1_792_512_364.754))
    }

    @Test func decodesBase32() {
        #expect(Base32.decode("mzxw6ytboi").flatMap { String(data: $0, encoding: .utf8) } == "foobar")
    }
}
