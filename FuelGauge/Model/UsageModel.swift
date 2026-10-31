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
    private(set) var usageEvents: [UsageEvent] = []
    private(set) var usageWarnings: [String] = []
    private(set) var scanningUsage = false
    private(set) var usageUpdatedAt: Date?
    private var usageScanner: UsageLogScanner?
    private let usageCacheURL: URL
    private(set) var updatedAt: Date?
    private(set) var codexResetCredits: ResetCredits?
    private(set) var codexResetsCheckedAt: Date?
    private(set) var checkingCodexResets = false
    private var codexResetsAttemptedAt: Date?
    private(set) var claudeStatusLine: ClaudeSettings.State = .off

    var onChange: (() -> Void)?
    /// After each completed refresh, with the new forecasts. Alerts hang off this, not `onChange`.
    var onRefresh: (([Forecast]) -> Void)?

    private let store: ReadingStore
    private var codex: CodexLogReader
    private let grokBot = GrokBotReader()
    private let cursor = CursorReader()
    /// Cursor is asked over the network, so at most every 10 minutes.
    private var cursorReadAt: Date?
    private let claude = ClaudeSettings()
    private let codexStateURL: URL
    private var timer: Timer?
    private var isRefreshing = false
    private let readsLiveData: Bool

    /// How much history forecasts and charts look at.
    nonisolated static let history: TimeInterval = 8 * 24 * 3600

    init(supportFolder: URL = Brand.supportFolder, readsLiveData: Bool = true,
         resetCredits: ResetCredits? = nil) {
        store = ReadingStore(folder: supportFolder.appending(path: "Readings"))
        usageCacheURL = supportFolder.appending(path: "usage-history-v1.json")
        codexStateURL = supportFolder.appending(path: "codex-state.json")
        let state = (try? Data(contentsOf: codexStateURL))
            .flatMap { try? JSONDecoder().decode(CodexLogReader.State.self, from: $0) }
        codex = CodexLogReader(state: state ?? CodexLogReader.State())
        self.readsLiveData = readsLiveData
        self.codexResetCredits = resetCredits
        if resetCredits != nil { codexResetsCheckedAt = Date() }
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
        refreshCodexResets()
        refreshUsage()
        guard !isRefreshing else { return }
        isRefreshing = true
        let enabled = Tracking.enabled(installed: installedProviders)
        let readsCodex = readsLiveData && enabled.contains(.codex)
        let readsGrokBot = readsLiveData && enabled.contains(.grokBot)
        let readsCursor = readsLiveData && enabled.contains(.cursor)
            && (cursorReadAt.map { Date().timeIntervalSince($0) >= 600 } ?? true)
        if readsCursor { cursorReadAt = Date() }
        let cursor = cursor
        let codex = codex
        let grokBot = grokBot
        let store = store
        let codexStateURL = codexStateURL
        // Demo data stands in for a set-up Mac, so it doesn't ask to set up Claude Code.
        claudeStatusLine = readsLiveData ? claude.state : .on
        Task {
            let (readings, updatedCodex) = await Task.detached(priority: .utility) {
                var polled = codex
                var fresh: [Reading] = []
                if readsCodex { fresh += polled.poll() }
                if readsGrokBot { fresh += grokBot.read() }
                if readsCursor { fresh += await cursor.read() }
                // Move Codex's place in its logs forward only once the readings are saved, so a failed
                // write is read again next time instead of lost.
                var kept = codex
                if (try? store.append(fresh)) != nil {
                    kept = polled
                    if readsCodex, let data = try? JSONEncoder().encode(polled.state) {
                        try? FileManager.default.createDirectory(
                            at: codexStateURL.deletingLastPathComponent(), withIntermediateDirectories: true
                        )
                        try? data.write(to: codexStateURL, options: .atomic)
                    }
                }
                let since = Date().addingTimeInterval(-Self.history)
                return (store.load(since: since).filter { enabled.contains($0.provider) }, kept)
            }.value
            self.codex = updatedCodex
            forecasts = ForecastEngine.forecasts(from: readings).filter { !isStale($0) }
            updatedAt = Date()
            isRefreshing = false
            onChange?()
            onRefresh?(forecasts)
        }
    }

    var visibleUsage: [UsageEvent] {
        let enabled = Set([Provider.claude, .codex].filter { Tracking.isEnabled($0) })
        return usageEvents.filter { enabled.contains($0.provider) }
    }

    func todayUsage(for provider: Provider, now: Date = Date()) -> UsageSummary {
        UsageSummary(UsageHistory.select(visibleUsage, interval: UsagePeriod.today.interval(now: now),
                                         provider: provider))
    }

    private func refreshUsage() {
        guard readsLiveData, !scanningUsage else { return }
        scanningUsage = true
        let scanner = usageScanner
        let cacheURL = usageCacheURL
        let enabled = Tracking.enabled(installed: installedProviders)
        Task {
            let (updated, events) = await Task.detached(priority: .utility) {
                var reader = scanner ?? UsageLogScanner(cacheURL: cacheURL)
                let events = reader.scan(enabled: enabled)
                return (reader, events)
            }.value
            usageScanner = updated
            usageEvents = events
            usageWarnings = updated.warnings
            usageUpdatedAt = Date()
            scanningUsage = false
            onChange?()
        }
    }

    #if DEBUG
    func setDemoUsage(_ events: [UsageEvent]) {
        usageEvents = events
        usageUpdatedAt = Date()
    }
    #endif

    func refreshCodexResets(force: Bool = false) {
        guard readsLiveData else { return }
        guard UserDefaults.standard.bool(forKey: ResetPreferences.codexEnabled),
              Tracking.enabled(installed: installedProviders).contains(.codex) else {
            codexResetCredits = nil
            codexResetsCheckedAt = nil
            codexResetsAttemptedAt = nil
            return
        }
        guard !checkingCodexResets else { return }
        guard force || codexResetsAttemptedAt.map({ Date().timeIntervalSince($0) >= 300 }) ?? true else { return }
        checkingCodexResets = true
        codexResetsAttemptedAt = Date()
        Task {
            let credits = await Task.detached(priority: .utility) { CodexResetReader().read() }.value
            checkingCodexResets = false
            guard UserDefaults.standard.bool(forKey: ResetPreferences.codexEnabled),
                  Tracking.isEnabled(.codex) else { return }
            codexResetCredits = credits
            codexResetsCheckedAt = credits == nil ? nil : Date()
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
