import FuelGaugeCore
import SwiftUI

/// Reset tracking, per account: Codex's reset credits, Claude's Fable allowance, and Claude's resets recorded
/// by hand.
struct ResetsSettingsView: View {
    let model: UsageModel
    @AppStorage(ResetPreferences.codexEnabled) private var codexEnabled = true
    @AppStorage(ResetPreferences.claudeUsageEnabled) private var claudeUsageEnabled = true
    /// The Claude account whose resets are being edited, by `Account.id`.
    @State private var selectedID = Account.qualifiedID(provider: .claude, slug: nil)
    @State private var fable = Entry()
    @State private var weekly = Entry()
    @State private var checkedAt = 0.0

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
                    ForEach(model.accounts(for: .codex)) { account in
                        LabeledContent(label(account, fallback: "Reset credits")) {
                            HStack {
                                Text(model.codexResetCredits(for: account)?.summary() ?? "Unknown")
                                    .foregroundStyle(.secondary)
                                Button(model.checkingCodexResets == account.id ? "Checking…" : "Refresh") {
                                    model.refreshCodexResets(force: true, account: account)
                                }
                                .disabled(model.checkingCodexResets != nil)
                            }
                        }
                    }
                }
            } header: {
                Text("Codex")
            } footer: {
                Text("On by default when tracking Codex. Every 5 minutes, Fuel Gauge asks the installed CLI using "
                    + "each account's existing sign-in for its reset credits. This contacts OpenAI. "
                    + "Redeem resets in Codex /usage.")
            }
            Section {
                Toggle("Read the Fable allowance from Claude Code", isOn: $claudeUsageEnabled)
                    .onChange(of: claudeUsageEnabled) { model.refreshClaudeUsage(force: true) }
                if claudeUsageEnabled {
                    ForEach(model.accounts(for: .claude)) { account in
                        LabeledContent(label(account, fallback: "Fable")) {
                            HStack {
                                Text(fableStatus(account))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                                Button(model.checkingClaudeUsage == account.id ? "Checking…" : "Refresh") {
                                    model.refreshClaudeUsage(force: true, account: account)
                                }
                                .disabled(model.checkingClaudeUsage != nil)
                            }
                        }
                    }
                }
            } header: {
                Text("Claude · Fable allowance")
            } footer: {
                Text("On by default when tracking Claude Code. Once an hour per account, a few minutes apart, Fuel "
                    + "Gauge asks the installed Claude Code CLI for your plan usage, using that account's existing "
                    + "sign-in. It sends no prompt, so it uses no tokens, and runs with your hooks, MCP servers, and "
                    + "settings off. This contacts Anthropic.")
            }
            Section {
                if model.accounts(for: .claude).count > 1 {
                    Picker("Account", selection: $selectedID) {
                        ForEach(model.accounts(for: .claude)) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                }
                Link("Open Claude Usage", destination: URL(string: "https://claude.ai/settings/usage")!)
                entry(.fable, $fable)
                entry(.weekly, $weekly)
                HStack {
                    Button("Save manual counts") {
                        checkedAt = Date().timeIntervalSince1970
                        save()
                    }
                    if checkedAt > 0 {
                        Button("Clear") {
                            checkedAt = 0
                            save()
                        }
                        let saved = Date(timeIntervalSince1970: checkedAt)
                        Text("Saved \(saved.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Claude · manual tracking")
            } footer: {
                Text("Claude offers limit resets, but doesn't share the balance with other apps. Check Usage while "
                    + "signed in to each account and record each kind here. Update the counts after using a reset.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 760)
        .onAppear(perform: load)
        .onChange(of: selectedID, load)
    }

    private var selected: Account {
        model.accounts(for: .claude).first { $0.id == selectedID }
            ?? model.accounts(for: .claude).first ?? .defaultAccount(.claude)
    }

    private func load() {
        let resets = ClaudeResets.load(from: .standard, account: selected)
        fable = Entry(available: resets.fable.available, expiry: resets.fable.expiresAt?.timeIntervalSince1970 ?? 0)
        weekly = Entry(available: resets.weekly.available,
                       expiry: resets.weekly.expiresAt?.timeIntervalSince1970 ?? 0)
        checkedAt = resets.recordedAt?.timeIntervalSince1970 ?? 0
    }

    private func save() {
        func date(_ seconds: Double) -> Date? { seconds > 0 ? Date(timeIntervalSince1970: seconds) : nil }
        ClaudeResets(fable: .init(available: fable.available, expiresAt: date(fable.savedExpiry)),
                     weekly: .init(available: weekly.available, expiresAt: date(weekly.savedExpiry)),
                     recordedAt: date(checkedAt))
            .save(to: .standard, account: selected)
    }

    /// The account's name when the tool has several, else what the row shows.
    private func label(_ account: Account, fallback: String) -> String {
        model.accounts(for: account.provider).count > 1 ? account.name : fallback
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

    private func fableStatus(_ account: Account) -> String {
        guard let usage = model.claudeUsage(for: account) else {
            return model.checkingClaudeUsage == account.id ? "Checking Claude Code…" : "Not checked yet"
        }
        let checked = "checked \(ForecastText.time(usage.checkedAt))"
        guard let fable = usage.model(named: "Fable") else { return "No Fable allowance on this plan · \(checked)" }
        let share = fable.usedPercentOfWeekly.map { ", \(ForecastText.percent($0)) of your week" } ?? ""
        return "Fable \(ForecastText.percent(fable.usedPercent)) used\(share) · \(checked)"
    }
}
