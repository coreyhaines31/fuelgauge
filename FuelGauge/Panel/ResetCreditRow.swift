import FuelGaugeCore
import PanelKit
import SwiftUI

/// Reset credits under a Codex account, and a Claude account's recorded Fable and weekly resets. The "Check resets
/// in Claude Usage" link sits in the Claude Code section's link bar.
struct ResetCreditRow: View {
    let account: Account
    let model: UsageModel
    let now: Date
    let openSettings: () -> Void
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = true
    // Each account's own keys; the default account's are the ones Fuel Gauge always used.
    @AppStorage private var claudeCount: Int
    @AppStorage private var claudeExpiry: Double
    @AppStorage private var claudeCheckedAt: Double
    @AppStorage private var fableCount: Int
    @AppStorage private var fableExpiry: Double

    init(account: Account, model: UsageModel, now: Date, openSettings: @escaping () -> Void) {
        self.account = account
        self.model = model
        self.now = now
        self.openSettings = openSettings
        _claudeCount = AppStorage(wrappedValue: 0, account.defaultsKey(ResetPreferences.claudeCount))
        _claudeExpiry = AppStorage(wrappedValue: 0, account.defaultsKey(ResetPreferences.claudeExpiry))
        _claudeCheckedAt = AppStorage(wrappedValue: 0, account.defaultsKey(ResetPreferences.claudeCheckedAt))
        _fableCount = AppStorage(wrappedValue: 0, account.defaultsKey(ResetPreferences.claudeFableCount))
        _fableExpiry = AppStorage(wrappedValue: 0, account.defaultsKey(ResetPreferences.claudeFableExpiry))
    }

    private var provider: Provider { account.provider }

    var body: some View {
        if provider == .codex {
            codex
        } else if provider == .claude {
            claude
        }
    }

    @ViewBuilder private var codex: some View {
        if codexEnabled || model.codexResetCredits(for: account) != nil {
            Row("↺ " + (model.codexResetCredits(for: account)?.summary(now: now) ?? "Reset availability unknown"),
                subtitle: codexLines.isEmpty ? nil : codexLines.joined(separator: "\n")) {
                Button(model.checkingCodexResets == account.id ? "Checking…" : "Refresh") {
                    model.refreshCodexResets(force: true, account: account)
                }
                .buttonStyle(.panelCompact)
                .disabled(model.checkingCodexResets != nil)
            }
            .subtitleLineLimit(nil)
        } else {
            Button("Set up reset tracking…", action: openSettings)
                .buttonStyle(.panelCompact)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
        }
    }

    private var codexLines: [String] {
        var lines: [String] = []
        if let credits = model.codexResetCredits(for: account), credits.availableCount > 0,
           let expiry = credits.nextExpiration, expiry > now {
            lines.append("Next expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
        }
        if let checked = model.codexResetsCheckedAt(for: account) {
            lines.append("Checked \(checked.formatted(date: .omitted, time: .shortened)) · Redeem in Codex /usage")
        }
        return lines
    }

    @ViewBuilder private var claude: some View {
        if claudeCheckedAt > 0 {
            claudeRow(.fable)
            claudeRow(.weekly)
            let recorded = Date(timeIntervalSince1970: claudeCheckedAt)
            Row("Recorded by hand", subtitle: recorded.formatted(date: .abbreviated, time: .shortened)) {
                Button("Update…", action: openSettings)
                    .buttonStyle(.panelCompact)
            }
        } else {
            Button("Record Claude resets…", action: openSettings)
                .buttonStyle(.panelCompact)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
        }
    }

    private var claudeResets: ClaudeResets {
        func date(_ seconds: Double) -> Date? { seconds > 0 ? Date(timeIntervalSince1970: seconds) : nil }
        return ClaudeResets(fable: .init(available: fableCount, expiresAt: date(fableExpiry)),
                            weekly: .init(available: claudeCount, expiresAt: date(claudeExpiry)),
                            recordedAt: date(claudeCheckedAt))
    }

    /// "↺ 3 Fable resets", what one does, and when they lapse, with a light when that's within a week.
    private func claudeRow(_ kind: ClaudeResets.Kind) -> some View {
        let resets = claudeResets
        let lines = [kind.explanation, resets.expiry(kind, now: now)].compactMap { $0 }
        return Row("↺ " + resets.summary(kind, now: now), subtitle: lines.joined(separator: "\n")) {
            if resets.expiresSoon(kind, now: now) { StatusLight(.caution, "Expiring") }
        }
        .subtitleLineLimit(nil)
    }
}
