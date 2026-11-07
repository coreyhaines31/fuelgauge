import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastJournalStoreTests {
    @Test func restartsAndOtherWritersPreserveHistoryWithoutRedundantWrites() throws {
        let fixtures = ForecastJournalTests()
        let url = temporaryFolder().appending(path: "forecasts.json")
        var first = ForecastJournalStore(url: url)
        let forecasts = ForecastEngine.forecasts(from: fixtures.history, now: fixtures.now)
        try first.refresh(forecasts: forecasts, readings: fixtures.history, now: fixtures.now, appVersion: "test")
        let saved = try Data(contentsOf: url)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        var restarted = ForecastJournalStore(url: url)
        try restarted.refresh(forecasts: forecasts, readings: fixtures.history,
                              now: fixtures.now.addingTimeInterval(60), appVersion: "test")
        #expect(restarted.journal == first.journal)
        #expect(try Data(contentsOf: url) == saved)
        #expect(try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
                == attributes[.modificationDate] as? Date)
        let later = fixtures.now.addingTimeInterval(3600)
        let readings = fixtures.history + [fixtures.reading(1, used: 25)]
        try restarted.refresh(forecasts: ForecastEngine.forecasts(from: readings, now: later),
                              readings: readings, now: later, appVersion: "test")
        try first.refresh(forecasts: [], readings: readings, now: later, appVersion: "test")
        #expect(first.journal == restarted.journal)
        #expect(first.journal.records.count == 2)
        #expect(first.journal.records[0].targets[0].outcome == .observed)
    }

    @Test func corruptOrUnsupportedHistoryIsNeverOverwritten() throws {
        for contents in ["broken JSON", "{\"schemaVersion\":999,\"records\":[]}"] {
            let url = temporaryFolder().appending(path: "forecasts.json")
            let original = Data(contents.utf8)
            try original.write(to: url)
            var store = ForecastJournalStore(url: url)
            #expect(throws: (any Error).self) {
                try store.refresh(forecasts: [], readings: [], now: Date(), appVersion: "test")
            }
            #expect(try Data(contentsOf: url) == original)
        }
    }

    @Test func failedWritesAreSurfacedWithoutInventingSavedRecords() throws {
        let url = temporaryFolder().appending(path: "file")
        try Data().write(to: url)
        var store = ForecastJournalStore(url: url.appending(path: "forecasts.json"))
        let fixtures = ForecastJournalTests()
        #expect(throws: (any Error).self) {
            try store.refresh(forecasts: ForecastEngine.forecasts(from: fixtures.history, now: fixtures.now),
                              readings: fixtures.history, now: fixtures.now, appVersion: "test")
        }
        #expect(store.journal.records.isEmpty)
    }
}
