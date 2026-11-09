import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ClaudeSettingsTests {
    @Test func wrapsAndRestoresAnExistingStatusLine() throws {
        let folder = temporaryFolder()
        let settingsURL = folder.appending(path: "settings.json")
        try Data(#"{"model":"opus","statusLine":{"type":"command","command":"~/bin/mine.sh","padding":2}}"#.utf8)
            .write(to: settingsURL)
        let settings = ClaudeSettings(settingsURL: settingsURL, wrappedURL: folder.appending(path: "wrapped.json"))
        #expect(settings.state == .otherCommand("~/bin/mine.sh"))

        try settings.install(command: "/opt/homebrew/bin/fuelgauge statusline")
        #expect(settings.state == .on)
        #expect(settings.wrappedCommand == "~/bin/mine.sh")
        let installed = try JSONSerialization.jsonObject(with: Data(contentsOf: settingsURL)) as? [String: Any]
        #expect(installed?["model"] as? String == "opus")
        #expect((installed?["statusLine"] as? [String: Any])?["padding"] as? Int == 2)
        #expect(FileManager.default.fileExists(atPath: settingsURL.path + ".fuelgauge-backup"))

        try settings.uninstall()
        #expect(settings.state == .otherCommand("~/bin/mine.sh"))
        #expect(settings.wrappedCommand == nil)
    }

    @Test func installsIntoEmptySettings() throws {
        let folder = temporaryFolder()
        let settings = ClaudeSettings(
            settingsURL: folder.appending(path: "settings.json"), wrappedURL: folder.appending(path: "wrapped.json")
        )
        #expect(settings.state == .off)
        try settings.install(command: "'/Applications/Fuel Gauge.app/Contents/MacOS/fuelgauge' statusline")
        #expect(settings.state == .on)
        try settings.uninstall()
        #expect(settings.state == .off)
    }

    /// Another tool (SlashVibe) wrapping `fuelgauge statusline` must never be saved as the command Fuel Gauge
    /// runs, or every status line refresh spawns itself forever.
    @Test func neverWrapsACommandThatRunsFuelGauge() throws {
        let folder = temporaryFolder()
        let settingsURL = folder.appending(path: "settings.json")
        let wrappedURL = folder.appending(path: "wrapped.json")
        let wrapper = "'/x/hook-relay' --statusline --forward-command '/opt/homebrew/bin/fuelgauge statusline'"
        try JSONSerialization.data(withJSONObject: ["statusLine": ["type": "command", "command": wrapper]])
            .write(to: settingsURL)
        let settings = ClaudeSettings(settingsURL: settingsURL, wrappedURL: wrappedURL)

        try settings.install(command: "/opt/homebrew/bin/fuelgauge statusline")
        #expect(settings.state == .on)
        #expect(settings.wrappedCommand == nil)

        try JSONSerialization.data(withJSONObject: ["type": "command", "command": wrapper]).write(to: wrappedURL)
        #expect(settings.wrappedCommand == nil)
    }

    @Test func recognizesFuelGaugeInvocations() {
        #expect(ClaudeSettings.runsFuelGauge("/opt/homebrew/bin/fuelgauge statusline"))
        #expect(ClaudeSettings.runsFuelGauge("'/Applications/Fuel Gauge.app/Contents/MacOS/fuelgauge' statusline"))
        #expect(ClaudeSettings.runsFuelGauge("relay --forward-command '/opt/homebrew/bin/fuelgauge statusline'"))
        #expect(!ClaudeSettings.runsFuelGauge("~/bin/mine.sh"))
    }
}
