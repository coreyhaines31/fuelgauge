import AppKit
import os
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    private static let logger = Logger(subsystem: "app.fuelgauge.FuelGauge", category: "Settings")

    let updater: Updater
    @State private var checksForUpdates: Bool
    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage(Preferences.menuBarTextKey) private var menuBarText = MenuBarText.none
    @State private var commandPath = CommandLineInstaller.installedPath
    @State private var commandNote: String?
    @State private var copiedPrompt = false

    init(updater: Updater) {
        self.updater = updater
        _checksForUpdates = State(initialValue: updater.checksAutomatically)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchesAtLogin)
                    .onChange(of: launchesAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                Picker("Next to the gauge", selection: $menuBarText) {
                    ForEach(MenuBarText.allCases) { Text($0.title).tag($0) }
                }
            } footer: {
                Text("The gauge shows the fuel left in whichever limit is closest to running out, and turns "
                    + "orange when one is forecast to run out before it resets.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            commandLineSection
            Section {
                Toggle("Check for updates automatically", isOn: $checksForUpdates)
                    .onChange(of: checksForUpdates) { _, enabled in updater.checksAutomatically = enabled }
                LabeledContent("Version \(Self.version)") {
                    Button("Check Now") { updater.checkForUpdates() }
                }
            } footer: {
                Text("Update checks are the only thing that goes online. Your usage never leaves your Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(height: 480)
    }

    /// The `fuelgauge` command: where it's installed, a way to install it, and the prompt for AI agents.
    private var commandLineSection: some View {
        Section {
            LabeledContent("fuelgauge command") {
                if let commandPath {
                    Text("Installed at \(commandPath)").foregroundStyle(.secondary)
                } else {
                    Button("Install…") {
                        commandNote = CommandLineInstaller.install()
                        commandPath = CommandLineInstaller.installedPath
                    }
                }
            }
            LabeledContent("Prompt for AI agents") {
                Button(copiedPrompt ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(CommandLineInstaller.agentPrompt, forType: .string)
                    copiedPrompt = true
                }
            }
        } header: {
            Text("Command line")
        } footer: {
            Text(commandNote ?? "Lets you, a script, or an AI agent check the forecast before a big task. "
                + "Paste the prompt into CLAUDE.md or AGENTS.md.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.logger.error("Couldn't change launch at login: \(error.localizedDescription)")
            launchesAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
