import Foundation
import FuelGaugeCore
import Observation

/// Collects readings from every tool that's turned on, saves them, and keeps the forecasts current.
/// Claude Code readings arrive through `fuelgauge statusline`, which writes to the same store; this model
/// picks them up on its next refresh. Claude Code and Codex can have several accounts, one per config folder;
/// each one's readings, checks, and resets are its own.
@MainActor
@Observable
final class UsageModel {
    private(set) var forecasts: [Forecast] = []
    private(set) var forecastHistory: ForecastHistory
    private(set) var usageEvents: [UsageEvent] = []
    private(set) var usageWarnings: [String] = []
    private(set) var scanningUsage = false
    private(set) var usageUpdatedAt: Date?
    private var usageScanner: UsageLogScanner?
    private let usageCacheURL: URL
    private(set) var updatedAt: Date?
    /// The tracked accounts. Saved to the app's defaults so the `fuelgauge` command sees the same list.
    private(set) var accounts: AccountList
    private let accountDefaults: UserDefaults
    private let persistsAccounts: Bool
    /// Each account's reset credits and Fable allowance, asked of the tools' CLIs.
    private let checks: AccountChecks
    private var claudeStatusLines: [String: ClaudeSettings.State] = [:]

    var onChange: (() -> Void)?
    /// After each completed refresh, with the new forecasts. Alerts hang off this, not `onChange`.
    var onRefresh: (([Forecast]) -> Void)?

    private let store: ReadingStore
    private let supportFolder: URL
    /// Each Codex account's place in its logs, by `Account.id`.
    private var codexReaders: [String: CodexLogReader] = [:]
    private let grokBot = GrokBotReader()
    private let cursor = CursorReader()
    /// Cursor is asked over the network, so at most every 10 minutes.
    private var cursorReadAt: Date?
    private var timer: Timer?
    private var isRefreshing = false
    private let readsLiveData: Bool

    /// How much history forecasts and charts look at.
    nonisolated static let history = ForecastEngine.historyDuration

    /// `accounts` stands in for the saved list (demo data); it's never saved.
    init(supportFolder: URL = Brand.supportFolder, readsLiveData: Bool = true,
         resetCredits: ResetCredits? = nil, accounts: AccountList? = nil,
         accountDefaults: UserDefaults = Tracking.defaults) {
        self.supportFolder = supportFolder
        store = ReadingStore(folder: supportFolder.appending(path: "Readings"))
        forecastHistory = ForecastHistory(folder: supportFolder)
        usageCacheURL = supportFolder.appending(path: "usage-history-v1.json")
        self.accountDefaults = accountDefaults
        persistsAccounts = accounts == nil && readsLiveData
        self.accounts = accounts ?? AccountList.load(from: accountDefaults)
        self.readsLiveData = readsLiveData
        checks = AccountChecks(store: store, supportFolder: supportFolder)
        if let resetCredits, let codex = self.accounts.defaultAccount(.codex) {
            checks.codexResetCredits[codex.id] = resetCredits
            checks.codexResetsCheckedAt[codex.id] = Date()
        }
        // Save the list once, so the command knows the default folders this app reads.
        if persistsAccounts, accountDefaults.data(forKey: AccountList.defaultsKey) == nil {
            self.accounts.save(to: accountDefaults)
        }
        if readsLiveData { checks.loadSavedUsage(for: self.accounts.accounts(for: .claude)) }
        syncCodexReaders()
        checks.onChange = { [weak self] in self?.onChange?() }
        checks.onUsage = { [weak self] in self?.refresh() }
    }

    // MARK: Accounts

    /// A tool's accounts, the default one first.
    func accounts(for provider: Provider) -> [Account] {
        accounts.accounts(for: provider)
    }

    func addAccount(_ account: Account) {
        accounts.add(account)
        accountsChanged()
    }

    func removeAccount(_ account: Account) {
        accounts.remove(account)
        checks.forget(account)
        claudeStatusLines[account.id] = nil
        accountsChanged()
    }

    func renameAccount(_ account: Account, to name: String) {
        accounts.rename(account, to: name)
        accountsChanged()
    }

    private func accountsChanged() {
        if persistsAccounts { accounts.save(to: accountDefaults) }
        syncCodexReaders()
        usageScanner?.setRoots(usageRoots)
        forecasts = accounts.label(forecasts)
        onChange?()
        refresh()
    }

    /// One Codex log reader per Codex account, each resuming where it left off.
    private func syncCodexReaders() {
        var readers: [String: CodexLogReader] = [:]
        for account in accounts.accounts(for: .codex) {
            if let reader = codexReaders[account.id] {
                readers[account.id] = reader
                continue
            }
            let state = (try? Data(contentsOf: codexStateURL(account)))
                .flatMap { try? JSONDecoder().decode(CodexLogReader.State.self, from: $0) }
            readers[account.id] = CodexLogReader(account: account, state: state ?? CodexLogReader.State())
        }
        codexReaders = readers
    }

    /// `codex-state.json` for the default account, `codex-state-<slug>.json` for another.
    private func codexStateURL(_ account: Account) -> URL {
        account.supportFile("codex-state", extension: "json", in: supportFolder)
    }

    private var usageRoots: [UsageLogScanner.Root] {
        accounts.accounts.flatMap(UsageLogScanner.Root.of)
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
        refreshAccountData()
        guard !isRefreshing else { return }
        isRefreshing = true
        let enabled = Tracking.enabled(installed: installedProviders)
        let readsCodex = readsLiveData && enabled.contains(.codex)
        let readsGrokBot = readsLiveData && enabled.contains(.grokBot)
        let readsCursor = readsLiveData && enabled.contains(.cursor)
            && (cursorReadAt.map { Date().timeIntervalSince($0) >= 600 } ?? true)
        if readsCursor { cursorReadAt = Date() }
        // Demo data stands in for a set-up Mac, so it doesn't ask to set up Claude Code.
        for account in accounts.accounts(for: .claude) {
            claudeStatusLines[account.id] = readsLiveData
                ? ClaudeSettings(account: account, supportFolder: supportFolder).state : .on
        }
        let pass = RefreshPass(
            enabled: enabled, readsCodex: readsCodex, readsGrokBot: readsGrokBot, readsCursor: readsCursor,
            codexReaders: codexReaders,
            codexStateURLs: Dictionary(uniqueKeysWithValues: accounts.accounts(for: .codex).map {
                ($0.id, codexStateURL($0))
            }),
            grokBot: grokBot, cursor: cursor, store: store, accounts: accounts,
            forecastHistory: forecastHistory, recordsForecasts: readsLiveData,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        )
        Task {
            let result = await Task.detached(priority: .utility) { await pass.run() }.value
            // Readers for accounts added while this ran start fresh on the next refresh.
            for (id, reader) in result.codexReaders where codexReaders[id] != nil { codexReaders[id] = reader }
            forecasts = result.forecasts
            forecastHistory = result.history
            updatedAt = result.at
            isRefreshing = false
            onChange?()
            onRefresh?(forecasts)
        }
    }

    /// The checks that ask a tool's CLI or read its logs on their own schedules.
    private func refreshAccountData() {
        refreshCodexResets()
        refreshClaudeUsage()
        refreshUsage()
    }

    var visibleUsage: [UsageEvent] {
        let enabled = Set([Provider.claude, .codex].filter { Tracking.isEnabled($0) })
        return usageEvents.filter { enabled.contains($0.provider) }
    }

    func todayUsage(for account: Account, now: Date = Date()) -> UsageSummary {
        UsageSummary(UsageHistory.select(visibleUsage, interval: UsagePeriod.today.interval(now: now),
                                         account: account))
    }

    private func refreshUsage() {
        guard readsLiveData, !scanningUsage else { return }
        scanningUsage = true
        let scanner = usageScanner
        let cacheURL = usageCacheURL
        let roots = usageRoots
        let enabled = Tracking.enabled(installed: installedProviders)
        Task {
            let (updated, events) = await Task.detached(priority: .utility) {
                var reader = scanner ?? UsageLogScanner(roots: roots, cacheURL: cacheURL)
                reader.setRoots(roots)
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

    func setDemoForecastHistory(_ journal: ForecastJournal, now: Date) {
        forecastHistory.summarize(journal, now: now)
    }
    #endif

    // MARK: Account checks

    func codexResetCredits(for account: Account) -> ResetCredits? { checks.codexResetCredits[account.id] }
    func codexResetsCheckedAt(for account: Account) -> Date? { checks.codexResetsCheckedAt[account.id] }
    var checkingCodexResets: String? { checks.checkingCodexResets }
    func claudeUsage(for account: Account) -> ClaudeUsage? { checks.claudeUsage[account.id] }
    var checkingClaudeUsage: String? { checks.checkingClaudeUsage }

    func refreshCodexResets(force: Bool = false, account: Account? = nil) {
        guard readsLiveData else { return }
        checks.refreshCodexResets(force: force, account: account, accounts: accounts(for: .codex),
                                  tracked: Tracking.enabled(installed: installedProviders).contains(.codex))
    }

    func refreshClaudeUsage(force: Bool = false, account: Account? = nil) {
        guard readsLiveData else { return }
        checks.refreshClaudeUsage(force: force, account: account, accounts: accounts(for: .claude),
                                  tracked: Tracking.enabled(installed: installedProviders).contains(.claude))
    }

    /// What to do when an account's week or Fable allowance runs short, from its recorded resets.
    func resetAdvice(for account: Account, now: Date = Date()) -> ResetAdvice? {
        let own = forecasts.filter { $0.key.provider == account.provider && $0.key.account == account.slug }
        return ResetAdvice.suggest(forecasts: own, usage: checks.claudeUsage[account.id],
                                   resets: ClaudeResets.load(from: .standard, account: account), now: now)
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
        case .learning, .stale, .makesIt: return 1_000_000_000 - forecast.usedPercent
        }
    }

    func claudeStatusLine(for account: Account) -> ClaudeSettings.State {
        claudeStatusLines[account.id] ?? .off
    }

    /// Claude accounts whose status line isn't Fuel Gauge's yet, so they send no readings.
    var claudeAccountsNeedingSetup: [Account] {
        guard installedProviders.contains(.claude), Tracking.isEnabled(.claude) else { return [] }
        return accounts(for: .claude).filter { claudeStatusLine(for: $0) != .on }
    }

    /// The same `fuelgauge statusline` command for every account: it reads `CLAUDE_CONFIG_DIR` to know which
    /// account a session is.
    func setClaudeStatusLine(on: Bool, account: Account) throws {
        let settings = ClaudeSettings(account: account, supportFolder: supportFolder)
        if on {
            try settings.install(command: StatusLineCommand.invocation())
        } else {
            try settings.uninstall()
        }
        claudeStatusLines[account.id] = settings.state
        onChange?()
    }
}
