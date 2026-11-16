import FuelGaugeCore
import PanelKit
import SwiftUI

/// Reset credits under Codex and Claude Code. The "Check resets in Claude Usage" link sits in the Claude Code
/// section's link bar.
struct ResetCreditRow: View {
    let provider: Provider
    let model: UsageModel
    let now: Date
    let openSettings: () -> Void
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = true
    @AppStorage(ResetPreferences.claudeCount) private var claudeCount = 0
    @AppStorage(ResetPreferences.claudeExpiry) private var claudeExpiry = 0.0
    @AppStorage(ResetPreferences.claudeCheckedAt) private var claudeCheckedAt = 0.0

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
            let expired = claudeExpiry > 0 && claudeExpiry <= now.timeIntervalSince1970
            let count = claudeCount == 1 ? "1 reset recorded" : "\(claudeCount) resets recorded"
            Row("↺ " + (expired ? "Recheck reset availability" : "\(count) · manual"),
                subtitle: claudeLines.joined(separator: "\n")) {
                Button("Update…", action: openSettings)
                    .buttonStyle(.panelCompact)
            }
            .subtitleLineLimit(nil)
        }
    }

    private var claudeLines: [String] {
        var lines: [String] = []
        if claudeCount > 0 && claudeExpiry > now.timeIntervalSince1970 {
            let expiry = Date(timeIntervalSince1970: claudeExpiry)
            lines.append("Next expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
        }
        let recorded = Date(timeIntervalSince1970: claudeCheckedAt)
        lines.append("Recorded \(recorded.formatted(date: .abbreviated, time: .shortened))")
        return lines
    }
}
