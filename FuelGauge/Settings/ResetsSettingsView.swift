import FuelGaugeCore
import SwiftUI

struct ResetsSettingsView: View {
    let model: UsageModel
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = true
    @AppStorage(ResetPreferences.claudeUsageEnabled) private var claudeUsageEnabled = true
    @AppStorage(ResetPreferences.claudeCount) private var savedWeekly = 0
    @AppStorage(ResetPreferences.claudeExpiry) private var savedWeeklyExpiry = 0.0
    @AppStorage(ResetPreferences.claudeFableCount) private var savedFable = 0
    @AppStorage(ResetPreferences.claudeFableExpiry) private var savedFableExpiry = 0.0
    @AppStorage(ResetPreferences.claudeCheckedAt) private var checkedAt = 0.0
    @State private var fable = Entry()
    @State private var weekly = Entry()

    /// One kind of reset as it's being edited.
    struct Entry {
        var available = 0
        var expires = false
        var expiry = Date().addingTimeInterval(86400)

        init() {}

        init(available: Int, expiry: Double) {
            self.available = available
            expires = expiry > 0
            if expires { self.expiry = Date(timeIntervalSince1970: expiry) }
        }

        var savedExpiry: Double { expires && available > 0 ? expiry.timeIntervalSince1970 : 0 }
    }

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
                Text("On by default when tracking Codex. Every 5 minutes, Fuel Gauge asks the installed CLI using "
                    + "its existing sign-in for your reset credits. This contacts OpenAI. "
                    + "Redeem resets in Codex /usage.")
            }
            Section {
                Toggle("Read the Fable allowance from Claude Code", isOn: $claudeUsageEnabled)
                    .onChange(of: claudeUsageEnabled) { model.refreshClaudeUsage(force: true) }
                if claudeUsageEnabled {
                    Text(fableStatus)
                    Button(model.checkingClaudeUsage ? "Checking…" : "Refresh") {
                        model.refreshClaudeUsage(force: true)
                    }
                    .disabled(model.checkingClaudeUsage)
                }
            } header: {
                Text("Claude · Fable allowance")
            } footer: {
                Text("On by default when tracking Claude Code. Every 10 minutes, Fuel Gauge asks the installed "
                    + "Claude Code CLI for your plan usage, using its existing sign-in. It sends no prompt, so it "
                    + "uses no tokens, and runs with your hooks, MCP servers, and settings off. This contacts "
                    + "Anthropic.")
            }
            Section {
                Link("Open Claude Usage", destination: URL(string: "https://claude.ai/settings/usage")!)
                entry(.fable, $fable)
                entry(.weekly, $weekly)
                HStack {
                    Button("Save manual counts") {
                        savedFable = fable.available
                        savedFableExpiry = fable.savedExpiry
                        savedWeekly = weekly.available
                        savedWeeklyExpiry = weekly.savedExpiry
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
                Text("Claude offers limit resets, but doesn't share the balance with other apps. Check Usage and "
                    + "record each kind here. Update the counts after using a reset or switching accounts.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 760)
        .onAppear {
            fable = Entry(available: savedFable, expiry: savedFableExpiry)
            weekly = Entry(available: savedWeekly, expiry: savedWeeklyExpiry)
        }
    }

    @ViewBuilder private func entry(_ kind: ClaudeResets.Kind, _ entry: Binding<Entry>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Stepper("\(kind.name) resets: \(entry.wrappedValue.available)", value: entry.available, in: 0...100)
            Text(kind.explanation)
                .font(.caption).foregroundStyle(.secondary)
        }
        Toggle("\(kind.name) resets expire", isOn: entry.expires)
        if entry.wrappedValue.expires {
            DatePicker("\(kind.name) expiration", selection: entry.expiry)
        }
    }

    private var fableStatus: String {
        guard let usage = model.claudeUsage else {
            return model.checkingClaudeUsage ? "Checking Claude Code…" : "Not checked yet"
        }
        let checked = "checked \(ForecastText.time(usage.checkedAt))"
        guard let fable = usage.model(named: "Fable") else { return "No Fable allowance on this plan · \(checked)" }
        let share = fable.usedPercentOfWeekly.map { ", \(ForecastText.percent($0)) of your week" } ?? ""
        return "Fable \(ForecastText.percent(fable.usedPercent)) used\(share) · \(checked)"
    }
}
