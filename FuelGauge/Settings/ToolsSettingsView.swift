import FuelGaugeCore
import SwiftUI

/// Which tools Fuel Gauge tracks, and where each one's numbers come from.
struct ToolsSettingsView: View {
    let model: UsageModel
    @State private var enabled: [Provider: Bool] = [:]
    @State private var claudeError: String?

    private let installed = Tracking.installed()

    var body: some View {
        Form {
            Section {
                ForEach(Self.tools, id: \.provider) { tool in
                    row(tool)
                }
            } footer: {
                Text("Fuel Gauge reads what these tools already save on your Mac. It never signs in to them, "
                    + "reads browser cookies, or sends your usage anywhere.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if installed.contains(.claude) {
                claudeSection
            }
        }
        .formStyle(.grouped)
        .frame(height: 430)
        .onAppear {
            let states = Self.tools.map { ($0.provider, Tracking.isEnabled($0.provider)) }
            enabled = Dictionary(uniqueKeysWithValues: states)
        }
    }

    private struct Tool {
        let provider: Provider
        let source: String
    }

    private static let tools = [
        Tool(provider: .claude, source: "5-hour and weekly limits, from Claude Code's status line."),
        Tool(provider: .codex, source: "Codex's limits, from its session logs in ~/.codex."),
        Tool(provider: .grokBot, source: "The weekly limit, from the usage Grok Bot saves while it's open.")
    ]

    private func row(_ tool: Tool) -> some View {
        let isInstalled = installed.contains(tool.provider)
        return Toggle(isOn: Binding(
            get: { isInstalled && (enabled[tool.provider] ?? true) },
            set: { value in
                enabled[tool.provider] = value
                Tracking.setEnabled(tool.provider, value)
                model.refresh()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.provider.name)
                Text(isInstalled ? tool.source : "Not found on this Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .disabled(!isInstalled)
    }

    private var claudeSection: some View {
        Section {
            LabeledContent("Status line") {
                switch model.claudeStatusLine {
                case .on:
                    Button("Turn Off") { setClaude(false) }
                case .off, .otherCommand:
                    Button("Turn On") { setClaude(true) }
                }
            }
        } header: {
            Text("Claude Code")
        } footer: {
            Text(claudeError ?? claudeFooter)
                .font(.caption).foregroundStyle(claudeError == nil ? .secondary : Color.red)
        }
    }

    private var claudeFooter: String {
        switch model.claudeStatusLine {
        case .on:
            "Claude Code shows the forecast under the prompt and Fuel Gauge reads each update. Turning it off "
                + "puts your old status line back."
        case .otherCommand:
            "You have your own status line. Turning this on keeps it, with the forecast underneath."
        case .off:
            "Claude Code only shares its limits with a status line. Settings are backed up first."
        }
    }

    private func setClaude(_ on: Bool) {
        do {
            try model.setClaudeStatusLine(on: on)
            claudeError = nil
        } catch {
            claudeError = "Couldn't update Claude Code's settings: \(error.localizedDescription)"
        }
    }
}
