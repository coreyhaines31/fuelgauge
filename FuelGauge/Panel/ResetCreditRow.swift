import FuelGaugeCore
import PanelKit
import SwiftUI

/// Reset credits under Codex, and Claude's recorded Fable and weekly resets under Claude Code. The "Check resets
/// in Claude Usage" link sits in the Claude Code section's link bar.
struct ResetCreditRow: View {
    let provider: Provider
    let model: UsageModel
    let now: Date
    let openSettings: () -> Void
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = true
    @AppStorage(ResetPreferences.claudeCount) private var claudeCount = 0
    @AppStorage(ResetPreferences.claudeExpiry) private var claudeExpiry = 0.0
    @AppStorage(ResetPreferences.claudeCheckedAt) private var claudeCheckedAt = 0.0
    @AppStorage(ResetPreferences.claudeFableCount) private var fableCount = 0
    @AppStorage(ResetPreferences.claudeFableExpiry) private var fableExpiry = 0.0

    var body: some View {
        if provider == .codex {
            codex
        } else if provider == .claude {
            claude
        }
    }

    @ViewBuilder private var codex: some View {
        if codexEnabled || model.codexResetCredits != nil {
            Row("↺ " + (model.codexResetCredits?.summary(now: now) ?? "Reset availability unknown"),
                subtitle: codexLines.isEmpty ? nil : codexLines.joined(separator: "\n")) {
                Button(model.checkingCodexResets ? "Checking…" : "Refresh") {
                    model.refreshCodexResets(force: true)
                }
                .buttonStyle(.panelCompact)
                .disabled(model.checkingCodexResets)
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
        if let credits = model.codexResetCredits, credits.availableCount > 0,
           let expiry = credits.nextExpiration, expiry > now {
            lines.append("Next expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
        }
        if let checked = model.codexResetsCheckedAt {
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
