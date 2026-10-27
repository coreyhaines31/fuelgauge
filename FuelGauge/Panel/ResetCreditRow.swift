import FuelGaugeCore
import SwiftUI

struct ResetCreditRow: View {
    let provider: Provider
    let model: UsageModel
    let now: Date
    let openSettings: () -> Void
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = false
    @AppStorage(ResetPreferences.claudeCount) private var claudeCount = 0
    @AppStorage(ResetPreferences.claudeExpiry) private var claudeExpiry = 0.0
    @AppStorage(ResetPreferences.claudeCheckedAt) private var claudeCheckedAt = 0.0

    var body: some View {
        if provider == .codex || provider == .claude {
            Divider()
            VStack(alignment: .leading, spacing: 3) {
                if provider == .codex {
                    codex
                } else {
                    claude
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var codex: some View {
        if codexEnabled || model.codexResetCredits != nil {
            HStack {
                Label(model.codexResetCredits?.summary(now: now) ?? "Reset availability unknown",
                      systemImage: "arrow.counterclockwise")
                Spacer()
                Button(model.checkingCodexResets ? "Checking…" : "Refresh") {
                    model.refreshCodexResets(force: true)
                }
                .buttonStyle(.borderless)
                .disabled(model.checkingCodexResets)
            }
            if let credits = model.codexResetCredits, credits.availableCount > 0,
               let expiry = credits.nextExpiration, expiry > now {
                Text("Next expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
            }
            if let checked = model.codexResetsCheckedAt {
                Text("Checked \(checked.formatted(date: .omitted, time: .shortened)) · Redeem in Codex /usage")
            }
        } else {
            Button("Set up reset tracking…", action: openSettings)
                .buttonStyle(.borderless)
        }
    }

    @ViewBuilder private var claude: some View {
        if claudeCheckedAt > 0 {
            let expired = claudeExpiry > 0 && claudeExpiry <= now.timeIntervalSince1970
            let count = claudeCount == 1 ? "1 reset recorded" : "\(claudeCount) resets recorded"
            HStack {
                Label(expired ? "Recheck reset availability" : "\(count) · manual",
                      systemImage: "arrow.counterclockwise")
                Spacer()
                Button("Update…", action: openSettings).buttonStyle(.borderless)
            }
            if claudeCount > 0 && claudeExpiry > now.timeIntervalSince1970 {
                let expiry = Date(timeIntervalSince1970: claudeExpiry)
                Text("Next expires \(expiry.formatted(date: .abbreviated, time: .shortened))")
            }
            let recorded = Date(timeIntervalSince1970: claudeCheckedAt)
            Text("Recorded \(recorded.formatted(date: .abbreviated, time: .shortened))")
        }
        Link("Check resets in Claude Usage", destination: URL(string: "https://claude.ai/settings/usage")!)
    }
}
