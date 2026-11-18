import FuelGaugeCore
import SwiftUI

/// Which tools Fuel Gauge tracks, where each one's numbers come from, and each tool's accounts.
struct ToolsSettingsView: View {
    let model: UsageModel
    @State private var enabled: [Provider: Bool] = [:]
    @State private var signedIn: [String: String] = [:]
    @State private var candidates: [Account] = []

    private let installed = Tracking.installed()

    var body: some View {
        Form {
            Section {
                ForEach(Self.tools, id: \.provider) { tool in
                    row(tool)
                }
            } footer: {
                Text("Fuel Gauge reads what these tools already save on your Mac. It never reads browser cookies "
                    + "or sends your usage anywhere. Codex reset checks contact OpenAI by default; turn them off "
                    + "in Settings › Resets. Cursor usage goes online only if you turn it on.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(Account.multiAccountProviders.filter(installed.contains), id: \.self) { provider in
                AccountsSection(provider: provider, model: model, signedIn: signedIn,
                                candidates: candidates, reload: reloadAccounts)
            }
        }
        .formStyle(.grouped)
        .frame(height: 620)
        .onAppear {
            let states = Self.tools.map { ($0.provider, Tracking.isEnabled($0.provider)) }
            enabled = Dictionary(uniqueKeysWithValues: states)
            reloadAccounts()
        }
    }

    /// Who's signed in to each account, and folders that look like more: file reads, so off the main thread.
    private func reloadAccounts() {
        let list = model.accounts, home = model.home
        // The demo's home folder stands in for the Mac's, so its environment mustn't pick a real folder either.
        let environment = home == .homeDirectory ? ProcessInfo.processInfo.environment : [:]
        Task {
            let (found, who) = await Task.detached(priority: .userInitiated) {
                let found = list.candidates(home: home)
                var who: [String: String] = [:]
                for account in list.accounts + found {
                    who[account.id] = account.signedInAs(home: home, environment: environment)
                }
                return (found, who)
            }.value
            candidates = found
            signedIn = who
        }
    }
    private struct Tool {
        let provider: Provider
        let source: String
    }

    private static let tools = [
        Tool(provider: .claude, source: "5-hour and weekly limits, from Claude Code's status line."),
        Tool(provider: .codex, source: "Codex's limits, from its session logs in ~/.codex."),
        Tool(provider: .grokBot, source: "The weekly limit, from the usage Grok Bot saves while it's open."),
        Tool(provider: .cursor, source: "The monthly limit. Off by default: Fuel Gauge asks cursor.com every 10 "
            + "minutes, signed in with the Cursor app's own sign-in. Nothing else is sent.")
    ]

    private func row(_ tool: Tool) -> some View {
        let isInstalled = installed.contains(tool.provider)
        return Toggle(isOn: Binding(
            get: { isInstalled && (enabled[tool.provider] ?? Tracking.isEnabled(tool.provider)) },
            set: { value in
                enabled[tool.provider] = value
                Tracking.setEnabled(tool.provider, value)
                model.refresh()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    ToolMark(provider: tool.provider, size: 13)
                    Text(tool.provider.name)
                }
                Text(isInstalled ? tool.source : "Not found on this Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .disabled(!isInstalled)
    }
}
