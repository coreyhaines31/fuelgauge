import Foundation
import FuelGaugeCore

/// One refresh's work off the main thread: read what's new from each tool and account, save it, and forecast
/// every tracked limit.
struct RefreshPass: Sendable {
    struct Result: Sendable {
        let forecasts: [Forecast]
        let codexReaders: [String: CodexLogReader]
        let history: ForecastHistory
        let at: Date
    }

    let enabled: [Provider]
    let readsCodex: Bool
    let readsGrokBot: Bool
    let readsCursor: Bool
    /// Each Codex account's reader, by `Account.id`.
    let codexReaders: [String: CodexLogReader]
    let codexStateURLs: [String: URL]
    let grokBot: GrokBotReader
    let cursor: CursorReader
    let store: ReadingStore
    let accounts: AccountList
    let forecastHistory: ForecastHistory
    let recordsForecasts: Bool
    let appVersion: String

    func run() async -> Result {
        var polled = codexReaders
        var fresh: [Reading] = []
        if readsCodex {
            for id in codexReaders.keys.sorted() {
                guard var reader = polled[id] else { continue }
                fresh += reader.poll()
                polled[id] = reader
            }
        }
        if readsGrokBot { fresh += grokBot.read() }
        if readsCursor { fresh += await cursor.read() }
        // Move Codex's place in its logs forward only once the readings are saved, so a failed write is read
        // again next time instead of lost.
        var kept = codexReaders
        if (try? store.append(fresh)) != nil {
            kept = polled
            if readsCodex {
                for (id, reader) in polled {
                    if let url = codexStateURLs[id] { Self.save(reader.state, to: url) }
                }
            }
        }
        let now = Date()
        let readings = tracked(store.load(since: now.addingTimeInterval(-ForecastEngine.historyDuration)))
        let recent = ForecastEngine.forecasts(from: readings, now: now).filter {
            $0.verdict != .reset || $0.resetsAt >= now.addingTimeInterval(-24 * 3600)
        }
        let forecasts = accounts.label(recent)
        var history = forecastHistory
        if recordsForecasts {
            history.refresh(forecasts: forecasts, readings: readings, now: now, appVersion: appVersion)
        }
        return Result(forecasts: forecasts, codexReaders: kept, history: history, at: now)
    }

    /// Readings from tools that are on, and accounts that are tracked: a removed account's readings stay on disk
    /// but out of sight.
    private func tracked(_ readings: [Reading]) -> [Reading] {
        readings.filter { reading in
            guard enabled.contains(reading.provider) else { return false }
            guard Account.multiAccountProviders.contains(reading.provider) else { return true }
            return accounts.account(reading.provider, slug: reading.account) != nil
        }
    }

    private static func save(_ state: CodexLogReader.State, to url: URL) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
