import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastAccuracyTests {
    @Test func comparesIdenticalOutcomesOnlyAfterEnoughDaysAndPairs() throws {
        let fixtures = ForecastJournalTests()
        let original = try fixtures.journal().records[0]
        var records: [ForecastRecord] = []
        for index in 0..<24 {
            var record = original
            record.targets[0].outcome = .observed
            record.targets[0].actual = fixtures.reading(1, used: 28)
            records.append(record)
            var journal = try decode(records)
            let key = original.source.key
            let short = ForecastAccuracy.summarize(journal, key: key, now: fixtures.now)[0]
            #expect(short.paired == index + 1)
            #expect(short.adaptiveMAE == nil)
            // Spread the same frozen comparison over three issue dates to exercise the reporting gate.
            var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(records))
                as? [[String: Any]])
            for entry in object.indices {
                object[entry]["issuedAt"] = fixtures.now.addingTimeInterval(-Double(entry % 3) * 86400)
                    .timeIntervalSinceReferenceDate
            }
            let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "records": object])
            journal = try JSONDecoder().decode(ForecastJournal.self, from: data)
            let result = ForecastAccuracy.summarize(journal, key: key, now: fixtures.now)[0]
            #expect(result.hasEnoughEvidence == (index + 1 >= 20))
            if result.hasEnoughEvidence {
                #expect(result.adaptiveMAE == 3)
                #expect(result.recentMAE == 3)
            }
        }
    }

    @Test func missingAndUnavailableForecastsDoNotImproveTheScore() throws {
        let fixtures = ForecastJournalTests()
        var record = try fixtures.journal().records[0]
        record.targets[0].outcome = .missing
        record.targets[1] = ForecastRecord.Target(hours: 6, at: fixtures.now.addingTimeInterval(21600),
            adaptive: nil, recent: record.targets[1].recent, outcome: .observed,
            actual: fixtures.reading(6, used: 30))
        let journal = try decode([record])
        let results = ForecastAccuracy.summarize(journal, key: record.source.key, now: fixtures.now)
        #expect(results[0].missing == 1)
        #expect(results[0].paired == 0)
        #expect(results[1].observed == 1)
        #expect(results[1].recentAvailable == 1)
        #expect(results[1].adaptiveAvailable == 0)
        #expect(results[1].paired == 0)
        #expect(results[2].pending == 1)
    }

    private func decode(_ records: [ForecastRecord]) throws -> ForecastJournal {
        let array = try JSONSerialization.jsonObject(with: JSONEncoder().encode(records))
        let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "records": array])
        return try JSONDecoder().decode(ForecastJournal.self, from: data)
    }
}
