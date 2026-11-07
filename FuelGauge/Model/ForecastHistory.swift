import Foundation
import FuelGaugeCore

struct ForecastHistory: Sendable {
    private var store: ForecastJournalStore
    private(set) var accuracy: [LimitKey: [ForecastAccuracy]] = [:]
    private(set) var firstRecordedAt: [LimitKey: Date] = [:]
    private(set) var warning: String?

    init(folder: URL) {
        store = ForecastJournalStore(url: folder.appending(path: "forecast-history-v1.json"))
    }

    mutating func refresh(forecasts: [Forecast], readings: [Reading], now: Date, appVersion: String) {
        do {
            try store.refresh(forecasts: forecasts, readings: readings, now: now, appVersion: appVersion)
            warning = nil
        } catch {
            warning = "Forecast recording is paused: \(error.localizedDescription) It will retry on the next refresh."
        }
        summarize(store.journal, now: now)
    }

    mutating func summarize(_ journal: ForecastJournal, now: Date) {
        let keys = Set(journal.records.map { $0.source.key })
        accuracy = Dictionary(uniqueKeysWithValues: keys.map {
            ($0, ForecastAccuracy.summarize(journal, key: $0, now: now))
        })
        firstRecordedAt = Dictionary(grouping: journal.records, by: { $0.source.key })
            .compactMapValues { $0.map(\.issuedAt).min() }
    }
}
