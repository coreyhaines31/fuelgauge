import Foundation
import FuelGaugeCore
import Observation

/// The checks that ask a tool's CLI about an account: Codex's reset credits every 5 minutes and Claude's Fable
/// allowance every hour. Each account is asked as itself, one account at a time, with automatic checks spaced
/// apart, so several accounts never stack their processes.
@MainActor
@Observable
final class AccountChecks {
    // Per account, by `Account.id`.
    var codexResetCredits: [String: ResetCredits] = [:]
    var codexResetsCheckedAt: [String: Date] = [:]
    private var codexResetsAttemptedAt: [String: Date] = [:]
    private(set) var checkingCodexResets: String?
    /// Claude's per-model allowances (Fable), from asking Claude Code. Missing until it answers.
    private(set) var claudeUsage: [String: ClaudeUsage] = [:]
    private var claudeUsageAttemptedAt: [String: Date] = [:]
    private(set) var checkingClaudeUsage: String?
    /// When the last automatic check of any account started, so several accounts' checks never run back to back.
    private var lastAutomaticClaudeCheck: Date?
    private var lastAutomaticCodexCheck: Date?
    /// Accounts removed while a check may still be running, so its answer is dropped.
    private var forgotten: Set<String> = []

    var onChange: (() -> Void)?
    /// After a Fable answer is saved as readings, so the forecasts pick it up.
    var onUsage: (() -> Void)?

    private let store: ReadingStore
    private let supportFolder: URL

    init(store: ReadingStore, supportFolder: URL) {
        self.store = store
        self.supportFolder = supportFolder
    }

    func loadSavedUsage(for accounts: [Account]) {
        for account in accounts {
            claudeUsage[account.id] = ClaudeUsage.load(from: ClaudeUsage.url(for: account, in: supportFolder))
        }
    }

    func forget(_ account: Account) {
        forgotten.insert(account.id)
        codexResetCredits[account.id] = nil
        codexResetsCheckedAt[account.id] = nil
        codexResetsAttemptedAt[account.id] = nil
        claudeUsage[account.id] = nil
        claudeUsageAttemptedAt[account.id] = nil
    }

    // MARK: Codex reset credits

    /// Asks each Codex account's CLI for its reset credits every 5 minutes, one account at a time and at least a
    /// minute apart. `account` with `force` asks that one now.
    func refreshCodexResets(force: Bool, account chosen: Account?, accounts: [Account], tracked: Bool) {
        guard UserDefaults.standard.bool(forKey: ResetPreferences.codexEnabled), tracked else {
            codexResetCredits = [:]
            codexResetsCheckedAt = [:]
            codexResetsAttemptedAt = [:]
            return
        }
        guard checkingCodexResets == nil else { return }
        let now = Date()
        let account: Account
        if force, let chosen {
            account = chosen
        } else {
            guard force || lastAutomaticCodexCheck.map({ now.timeIntervalSince($0) >= 60 }) ?? true,
                  let due = accounts.first(where: { account in
                      force || codexResetsAttemptedAt[account.id].map { now.timeIntervalSince($0) >= 300 } ?? true
                  }) else { return }
            account = due
            lastAutomaticCodexCheck = now
        }
        checkingCodexResets = account.id
        forgotten.remove(account.id)
        codexResetsAttemptedAt[account.id] = now
        Task {
            let credits = await Task.detached(priority: .utility) { CodexResetReader(account: account).read() }.value
            checkingCodexResets = nil
            guard UserDefaults.standard.bool(forKey: ResetPreferences.codexEnabled),
                  Tracking.isEnabled(.codex), !forgotten.contains(account.id) else { return }
            codexResetCredits[account.id] = credits
            codexResetsCheckedAt[account.id] = credits == nil ? nil : Date()
            onChange?()
        }
    }

    // MARK: Claude's Fable allowance

    /// Asks Claude Code for each account's Fable allowance once an hour, saves it as readings so it gets a
    /// forecast, and keeps the answer for the planner and the command. Accounts take turns, at least 5 minutes
    /// apart, so several accounts never stack their checks. `account` with `force` asks that one now.
    func refreshClaudeUsage(force: Bool, account chosen: Account?, accounts claudeAccounts: [Account],
                            tracked: Bool) {
        guard UserDefaults.standard.bool(forKey: ResetPreferences.claudeUsageEnabled), tracked else {
            claudeUsage = [:]
            for account in claudeAccounts {
                try? FileManager.default.removeItem(at: ClaudeUsage.url(for: account, in: supportFolder))
            }
            claudeUsageAttemptedAt = [:]
            return
        }
        guard checkingClaudeUsage == nil else { return }
        let now = Date()
        let account: Account
        if force, let chosen {
            account = chosen
        } else {
            guard force || lastAutomaticClaudeCheck.map({ now.timeIntervalSince($0) >= 300 }) ?? true,
                  let due = claudeAccounts.first(where: { account in
                      force || claudeUsageAttemptedAt[account.id].map { now.timeIntervalSince($0) >= 3600 } ?? true
                  }) else { return }
            account = due
            lastAutomaticClaudeCheck = now
        }
        checkingClaudeUsage = account.id
        forgotten.remove(account.id)
        claudeUsageAttemptedAt[account.id] = now
        let store = store, url = ClaudeUsage.url(for: account, in: supportFolder)
        Task {
            let usage = await Task.detached(priority: .utility) { ClaudeUsageReader(account: account).read() }.value
            checkingClaudeUsage = nil
            // Turned off, or the account removed, while the check ran: keep nothing from it.
            guard UserDefaults.standard.bool(forKey: ResetPreferences.claudeUsageEnabled),
                  Tracking.isEnabled(.claude), !forgotten.contains(account.id) else { return }
            // A failed check keeps the last answer: Fable's share of the week only grows until it resets.
            guard let usage else { return }
            claudeUsage[account.id] = usage
            await Task.detached(priority: .utility) {
                try? store.append(usage.readings(account: account.slug), now: usage.checkedAt)
                try? usage.save(to: url)
            }.value
            onChange?()
            onUsage?()
        }
    }
}
