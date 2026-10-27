import SwiftUI

struct ResetsSettingsView: View {
    let model: UsageModel
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = false
    @AppStorage(ResetPreferences.claudeCount) private var savedCount = 0
    @AppStorage(ResetPreferences.claudeExpiry) private var savedExpiry = 0.0
    @AppStorage(ResetPreferences.claudeCheckedAt) private var checkedAt = 0.0
    @State private var resetCount = 0
    @State private var expires = false
    @State private var expiry = Date().addingTimeInterval(86400)

    var body: some View {
        Form {
            Section {
                Toggle("Track Codex reset credits", isOn: $codexEnabled)
                    .onChange(of: codexEnabled) { model.refreshCodexResets(force: true) }
                if codexEnabled {
                    Text(model.codexResetCredits?.summary() ?? "Reset availability unknown")
                    Button(model.checkingCodexResets ? "Checking…" : "Refresh") {
                        model.refreshCodexResets(force: true)
                    }
                    .disabled(model.checkingCodexResets)
                }
            } header: {
                Text("Codex")
            } footer: {
                Text("Every 5 minutes, Fuel Gauge asks the installed Codex CLI for your reset credits using "
                    + "its existing sign-in. This contacts OpenAI. Use /usage in Codex to redeem a reset.")
            }
            Section {
                Link("Open Claude Usage", destination: URL(string: "https://claude.ai/settings/usage")!)
                Stepper("Available resets: \(resetCount)", value: $resetCount, in: 0...100)
                Toggle("Has an expiration", isOn: $expires)
                if expires {
                    DatePicker("Next expiration", selection: $expiry)
                }
                HStack {
                    Button("Save manual count") {
                        savedCount = resetCount
                        savedExpiry = expires && resetCount > 0 ? expiry.timeIntervalSince1970 : 0
                        checkedAt = Date().timeIntervalSince1970
                    }
                    if checkedAt > 0 {
                        Button("Clear") { checkedAt = 0 }
                        let saved = Date(timeIntervalSince1970: checkedAt)
                        Text("Saved \(saved.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Claude · manual tracking")
            } footer: {
                Text("Claude offers limit resets, but doesn't share the balance with its status line. "
                    + "Check Usage and record the count here. Update it after redeeming a reset or switching accounts.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 570)
        .onAppear {
            resetCount = savedCount
            expires = savedExpiry > 0
            if expires { expiry = Date(timeIntervalSince1970: savedExpiry) }
        }
    }
}
