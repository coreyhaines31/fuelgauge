import Foundation

/// Links the bundled `fuelgauge` command onto the PATH, for people who didn't install with Homebrew.
enum CommandLineInstaller {
    private static let homebrew = "/opt/homebrew/bin"
    private static let system = "/usr/local/bin"

    /// What to paste into Claude Code or Codex, or a CLAUDE.md or AGENTS.md, so an agent uses the command well.
    static let agentPrompt = """
        Before starting a long or expensive task, run `fuelgauge status`. If it exits with code 2, a Claude \
        Code, Codex, or Grok Bot limit is forecast to run out before it resets: tell me which one and when, \
        and ask before starting, or switch to a cheaper model. `fuelgauge status --json` has the details.
        """

    private static var tool: String? {
        Bundle.main.url(forAuxiliaryExecutable: "fuelgauge")?.path
    }

    /// Where the command is linked onto the PATH, or nil if it isn't.
    static var installedPath: String? {
        guard let tool, let real = realPath(tool) else { return nil }
        return [homebrew, system].map { "\($0)/fuelgauge" }.first { realPath($0) == real }
    }

    /// Installs the link and describes what happened.
    static func install() -> String {
        guard let tool else {
            return "This copy of Fuel Gauge doesn't include the command. "
                + "Download the latest version from fuelgauge.app."
        }
        if let installedPath {
            return "The fuelgauge command is already installed at \(installedPath)."
        }
        let manager = FileManager.default
        if manager.isWritableFile(atPath: homebrew) {
            let link = "\(homebrew)/fuelgauge"
            if manager.fileExists(atPath: link) || destination(link) != nil {
                guard isOurs(link) else {
                    return "Something else is already installed at \(link), so Fuel Gauge left it alone."
                }
                try? manager.removeItem(atPath: link)
            }
            do {
                try manager.createSymbolicLink(atPath: link, withDestinationPath: tool)
                return "Installed the fuelgauge command at \(link). Open a new Terminal window to use it."
            } catch {
                return "Couldn't install the fuelgauge command: \(error.localizedDescription)"
            }
        }
        let link = "\(system)/fuelgauge"
        if manager.fileExists(atPath: link) || destination(link) != nil, !isOurs(link) {
            return "Something else is already installed at \(link), so Fuel Gauge left it alone."
        }
        // /usr/local/bin needs an administrator, so macOS asks for a password.
        let command = "mkdir -p \(system) && ln -sfn \(shellQuoted(tool)) \(link)"
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        var error: NSDictionary?
        NSAppleScript(source: "do shell script \"\(escaped)\" with administrator privileges")?
            .executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "unknown error"
            return (error[NSAppleScript.errorNumber] as? Int) == -128
                ? "Didn't install the fuelgauge command."
                : "Couldn't install the fuelgauge command: \(message)"
        }
        return "Installed the fuelgauge command at \(link). Open a new Terminal window to use it."
    }

    /// Whether the path is a link to some copy of Fuel Gauge's command, like one from an earlier install.
    private static func isOurs(_ path: String) -> Bool {
        destination(path)?.hasSuffix(".app/Contents/MacOS/fuelgauge") == true
    }

    /// Where a symbolic link points, or nil if the path isn't one.
    private static func destination(_ path: String) -> String? {
        try? FileManager.default.destinationOfSymbolicLink(atPath: path)
    }

    /// The path with every link resolved, or nil if nothing is there.
    private static func realPath(_ path: String) -> String? {
        guard let real = realpath(path, nil) else { return nil }
        defer { free(real) }
        return String(cString: real)
    }

    private static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
