import Darwin
import Foundation

/// Asks the installed Claude Code CLI for its plan usage through its `get_usage` control request, using its
/// existing sign-in. No prompt is sent, so it uses no tokens, and Fuel Gauge never reads Claude's
/// credentials. Hooks, MCP servers, settings, and tools stay off so the run has no side effects.
public struct ClaudeUsageReader: Sendable {
    public var executable: URL?
    public var timeout: TimeInterval
    /// Set for the run, on top of Fuel Gauge's own environment. Another account's `CLAUDE_CONFIG_DIR` goes here:
    /// Claude Code picks the Keychain sign-in by that folder, so the check runs as that account.
    public var environment: [String: String]

    public init(executable: URL? = Self.findExecutable(), timeout: TimeInterval = 30,
                environment: [String: String] = [:]) {
        self.executable = executable
        self.timeout = timeout
        self.environment = environment
    }

    /// Asks as one account.
    public init(account: Account, executable: URL? = Self.findExecutable()) {
        self.init(executable: executable, environment: account.environment)
    }

    static let arguments = [
        "-p", "--verbose", "--input-format", "stream-json", "--output-format", "stream-json",
        "--setting-sources", "", "--settings", #"{"disableAllHooks":true}"#, "--strict-mcp-config",
        "--disable-slash-commands", "--tools", "", "--no-session-persistence"
    ]

    public static func findExecutable() -> URL? {
        let home = URL.homeDirectory
        var directories = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        directories += [home.appending(path: ".local/bin").path, home.appending(path: ".claude/local").path,
                        "/opt/homebrew/bin", "/usr/local/bin"]
        let node = home.appending(path: ".nvm/versions/node")
        let versions = (try? FileManager.default.contentsOfDirectory(atPath: node.path)) ?? []
        directories += versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
            .map { node.appending(path: "\($0)/bin").path }
        return directories.map { URL(filePath: $0).appending(path: "claude") }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    /// Blocking, bounded IO: call from a background task.
    public func read(now: () -> Date = Date.init) -> ClaudeUsage? {
        guard let executable else { return nil }
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        _ = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
        process.executableURL = executable
        process.arguments = Self.arguments
        // An empty folder, so no project settings or CLAUDE.md come along.
        let folder = FileManager.default.temporaryDirectory.appending(path: "FuelGaugeClaudeUsage")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        process.currentDirectoryURL = folder
        var environment = ProcessInfo.processInfo.environment.merging(self.environment) { $1 }
        environment["PATH"] = executable.deletingLastPathComponent().path + ":"
            + (environment["PATH"] ?? "/usr/bin:/bin")
        process.environment = environment
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        defer {
            try? input.fileHandleForWriting.close()
            if process.isRunning {
                process.terminate()
                let deadline = Date().addingTimeInterval(0.5)
                while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            }
            process.waitUntilExit()
            try? output.fileHandleForReading.close()
        }
        guard send(request("fuelgauge-init", ["subtype": "initialize"]), to: input.fileHandleForWriting) else {
            return nil
        }
        return receive(output.fileHandleForReading, input: input.fileHandleForWriting, now: now)
    }

    private func request(_ id: String, _ body: [String: Any]) -> [String: Any] {
        ["type": "control_request", "request_id": id, "request": body]
    }

    private func send(_ message: [String: Any], to handle: FileHandle) -> Bool {
        do {
            var data = try JSONSerialization.data(withJSONObject: message, options: .withoutEscapingSlashes)
            data.append(0x0A)
            try handle.write(contentsOf: data)
            return true
        } catch { return false }
    }

    private func receive(_ output: FileHandle, input: FileHandle, now: () -> Date) -> ClaudeUsage? {
        let deadline = Date().addingTimeInterval(timeout)
        var pending = Data()
        var asked = false
        while Date() < deadline {
            var descriptor = pollfd(fd: output.fileDescriptor, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 100) > 0 else { continue }
            let chunk = output.availableData
            guard !chunk.isEmpty, pending.count + chunk.count <= 8_388_608 else { return nil }
            pending.append(chunk)
            while let newline = pending.firstIndex(of: 0x0A) {
                let line = Data(pending[..<newline])
                pending.removeSubrange(...newline)
                guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                      message["type"] as? String == "control_response",
                      let response = message["response"] as? [String: Any] else { continue }
                let id = response["request_id"] as? String
                guard response["subtype"] as? String == "success" else {
                    if id == "fuelgauge-init" || id == "fuelgauge-usage" { return nil }
                    continue
                }
                if id == "fuelgauge-init" && !asked {
                    asked = true
                    let usage = request("fuelgauge-usage", ["subtype": "get_usage", "skip_behaviors": true])
                    guard send(usage, to: input) else { return nil }
                } else if id == "fuelgauge-usage", asked, let result = response["response"],
                          let data = try? JSONSerialization.data(withJSONObject: result) {
                    return ClaudeUsage.decode(data, at: now())
                }
            }
        }
        return nil
    }
}
