import Foundation

/// Turns Fuel Gauge's status line on and off in Claude Code's `settings.json`. If someone already has a
/// status line command, it's saved and kept running: `fuelgauge statusline` prints its output under the
/// forecast strip, and turning Fuel Gauge off puts it back.
public struct ClaudeSettings: Sendable {
    public enum State: Equatable, Sendable {
        case off
        case on
        /// Some other command is the status line, and Fuel Gauge isn't wrapping it yet.
        case otherCommand(String)
    }

    public let settingsURL: URL
    /// Where the status line command Fuel Gauge replaced is kept.
    public let wrappedURL: URL

    public init(
        settingsURL: URL = Self.defaultSettingsURL,
        wrappedURL: URL = Brand.supportFolder.appending(path: "wrapped-statusline.json")
    ) {
        self.settingsURL = settingsURL
        self.wrappedURL = wrappedURL
    }

    public static var defaultSettingsURL: URL {
        let configDir = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"].map { URL(filePath: $0) }
        return (configDir ?? URL.homeDirectory.appending(path: ".claude")).appending(path: "settings.json")
    }

    /// Whether Claude Code looks installed: its settings folder exists.
    public var isInstalled: Bool {
        FileManager.default.fileExists(atPath: settingsURL.deletingLastPathComponent().path)
    }

    public var state: State {
        guard let command = currentCommand() else { return .off }
        return Self.isOurs(command) ? .on : .otherCommand(command)
    }

    /// The status line command Fuel Gauge runs after its own strip, if it replaced one.
    public var wrappedCommand: String? {
        guard let data = try? Data(contentsOf: wrappedURL),
              let saved = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return saved["command"] as? String
    }

    /// Makes `command` (the full `… statusline` invocation) Claude Code's status line. Backs up
    /// `settings.json` first.
    public func install(command: String) throws {
        var settings = try readSettings()
        var statusLine = settings["statusLine"] as? [String: Any] ?? [:]
        if let existing = statusLine["command"] as? String, !Self.isOurs(existing) {
            try FileManager.default.createDirectory(
                at: wrappedURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let saved = try JSONSerialization.data(withJSONObject: statusLine, options: [.prettyPrinted, .sortedKeys])
            try saved.write(to: wrappedURL, options: .atomic)
        }
        statusLine["type"] = "command"
        statusLine["command"] = command
        settings["statusLine"] = statusLine
        try backUp()
        try write(settings)
    }

    /// Takes Fuel Gauge out of the status line and puts back the command it replaced, if any.
    public func uninstall() throws {
        var settings = try readSettings()
        guard let command = (settings["statusLine"] as? [String: Any])?["command"] as? String,
              Self.isOurs(command) else { return }
        if let data = try? Data(contentsOf: wrappedURL),
           let saved = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings["statusLine"] = saved
        } else {
            settings.removeValue(forKey: "statusLine")
        }
        try backUp()
        try write(settings)
        try? FileManager.default.removeItem(at: wrappedURL)
    }

    static func isOurs(_ command: String) -> Bool {
        command.contains("fuelgauge") && command.hasSuffix(" statusline")
    }

    private func currentCommand() -> String? {
        guard let settings = try? readSettings() else { return nil }
        return (settings["statusLine"] as? [String: Any])?["command"] as? String
    }

    private func readSettings() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return [:] }
        let data = try Data(contentsOf: settingsURL)
        guard !data.isEmpty else { return [:] }
        guard let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return settings
    }

    private func write(_ settings: [String: Any]) throws {
        try FileManager.default.createDirectory(
            at: settingsURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(
            withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        try data.write(to: settingsURL, options: .atomic)
    }

    private func backUp() throws {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return }
        let backup = settingsURL.appendingPathExtension("fuelgauge-backup")
        try? FileManager.default.removeItem(at: backup)
        try FileManager.default.copyItem(at: settingsURL, to: backup)
    }
}
