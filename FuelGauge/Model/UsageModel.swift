import Foundation
import FuelGaugeCore
import Observation

/// Collects readings from every tool that's turned on, saves them, and keeps the forecasts current.
/// Claude Code readings arrive through `fuelgauge statusline`, which writes to the same store; this model
/// picks them up on its next refresh.
@MainActor
@Observable
final class UsageModel {
    private(set) var forecasts: [Forecast] = []
    private(set) var updatedAt: Date?
    private(set) var claudeStatusLine: ClaudeSettings.State = .off

    var onChange: (() -> Void)?

    private let store: ReadingStore
    private var codex: CodexLogReader
    private let grokBot = GrokBotReader()
    private let claude = ClaudeSettings()
    private let codexStateURL: URL
    private var timer: Timer?
    private var isRefreshing = false
    private let readsLiveData: Bool

    /// How much history forecasts and charts look at.
    nonisolated static let history: TimeInterval = 8 * 24 * 3600

    init(supportFolder: URL = Brand.supportFolder, readsLiveData: Bool = true) {
        store = ReadingStore(folder: supportFolder.appending(path: "Readings"))
        codexStateURL = supportFolder.appending(path: "codex-state.json")
        let state = (try? Data(contentsOf: codexStateURL))
            .flatMap { try? JSONDecoder().decode(CodexLogReader.State.self, from: $0) }
        codex = CodexLogReader(state: state ?? CodexLogReader.State())
        self.readsLiveData = readsLiveData
    }

    /// Tools that look installed on this Mac, whether or not they're turned on.
    var installedProviders: [Provider] {
        Tracking.installed()
    }

    func start() {
        // Keep about two months of readings.
        let store = store
        Task.detached(priority: .background) { store.prune(before: Date().addingTimeInterval(-60 * 86400)) }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            MainActor.assumeIsolated { self.refresh() }
        }
    }

    /// Reads anything new, saves it, and recomputes the forecasts.
    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        let enabled = Tracking.enabled(installed: installedProviders)
        let readsCodex = readsLiveData && enabled.contains(.codex)
        let readsGrokBot = readsLiveData && enabled.contains(.grokBot)
        let codex = codex
        let grokBot = grokBot
        let store = store
        let codexStateURL = codexStateURL
        // Demo data stands in for a set-up Mac, so it doesn't ask to set up Claude Code.
        claudeStatusLine = readsLiveData ? claude.state : .on
        Task {
            let (readings, updatedCodex) = await Task.detached(priority: .utility) {
                var codex = codex
                var fresh: [Reading] = []
                if readsCodex {
                    fresh += codex.poll()
                    if let data = try? JSONEncoder().encode(codex.state) {
                        try? FileManager.default.createDirectory(
                            at: codexStateURL.deletingLastPathComponent(), withIntermediateDirectories: true
                        )
                        try? data.write(to: codexStateURL, options: .atomic)
                    }
                }
                if readsGrokBot { fresh += grokBot.read() }
                try? store.append(fresh)
                let since = Date().addingTimeInterval(-Self.history)
                return (store.load(since: since).filter { enabled.contains($0.provider) }, codex)
            }.value
            self.codex = updatedCodex
            forecasts = ForecastEngine.forecasts(from: readings).filter { !isStale($0) }
            updatedAt = Date()
            isRefreshing = false
            onChange?()
        }
    }

    /// A window that reset more than a day ago, with no reading since, isn't worth a card.
    private func isStale(_ forecast: Forecast) -> Bool {
        forecast.verdict == .reset && forecast.resetsAt < Date().addingTimeInterval(-24 * 3600)
    }

    /// The forecast that matters most: one that runs out soonest, else the fullest.
    var mostUrgent: Forecast? {
        byUrgency.first
    }

    /// Out first, then by how soon each runs out, then fullest first.
    var byUrgency: [Forecast] {
        forecasts.sorted { lhs, rhs in
            let (left, right) = (Self.urgency(lhs), Self.urgency(rhs))
            return left == right ? lhs.key < rhs.key : left < right
        }
    }

    private static func urgency(_ forecast: Forecast) -> Double {
        switch forecast.verdict {
        case .limitReached: return -1
        case .runsOut(let at, _, _): return at.timeIntervalSinceNow
        case .reset: return .greatestFiniteMagnitude
        case .learning, .makesIt: return 1_000_000_000 - forecast.usedPercent
        }
    }

    func setClaudeStatusLine(on: Bool) throws {
        if on {
            try claude.install(command: StatusLineCommand.invocation())
        } else {
            try claude.uninstall()
        }
        claudeStatusLine = claude.state
        onChange?()
    }
}
