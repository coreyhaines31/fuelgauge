import Darwin
import Foundation

/// Asks the installed Codex CLI for account data without reading its credentials or redeeming credits.
public struct CodexResetReader: Sendable {
    public var executable: URL?
    public var timeout: TimeInterval

    public init(executable: URL? = Self.findExecutable(), timeout: TimeInterval = 15) {
        self.executable = executable
        self.timeout = timeout
    }

    public static func findExecutable() -> URL? {
        let home = URL.homeDirectory
        var directories = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        directories += ["/opt/homebrew/bin", "/usr/local/bin", home.appending(path: ".local/bin").path]
        let node = home.appending(path: ".nvm/versions/node")
        let versions = (try? FileManager.default.contentsOfDirectory(atPath: node.path)) ?? []
        directories += versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
            .map { node.appending(path: "\($0)/bin").path }
        return directories.map { URL(filePath: $0).appending(path: "codex") }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    /// Blocking, bounded IO: call from a background task.
    public func read() -> ResetCredits? {
        guard let executable else { return nil }
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        // npm launchers need node beside codex even when launched from a GUI app.
        var environment = ProcessInfo.processInfo.environment
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
        let initialize: [String: Any] = [
            "method": "initialize", "id": 1,
            "params": ["clientInfo": ["name": "fuelgauge", "version": "0.1.0"]]
        ]
        guard send(initialize, to: input.fileHandleForWriting) else { return nil }
        return receive(output.fileHandleForReading, input: input.fileHandleForWriting)
    }

    private func send(_ message: [String: Any], to handle: FileHandle) -> Bool {
        do {
            var data = try JSONSerialization.data(withJSONObject: message, options: .withoutEscapingSlashes)
            data.append(0x0A)
            try handle.write(contentsOf: data)
            return true
        } catch { return false }
    }

    private func receive(_ output: FileHandle, input: FileHandle) -> ResetCredits? {
        let deadline = Date().addingTimeInterval(timeout)
        var pending = Data()
        var initialized = false
        while Date() < deadline {
            var descriptor = pollfd(fd: output.fileDescriptor, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 100) > 0 else { continue }
            let chunk = output.availableData
            guard !chunk.isEmpty, pending.count + chunk.count <= 1_048_576 else { return nil }
            pending.append(chunk)
            while let newline = pending.firstIndex(of: 0x0A) {
                let line = Data(pending[..<newline])
                pending.removeSubrange(...newline)
                guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                      let identifier = message["id"] as? Int else { continue }
                if message["error"] != nil { return nil }
                if identifier == 1 && !initialized {
                    initialized = true
                    guard send(["method": "initialized", "params": [:]], to: input),
                          send(["method": "account/rateLimits/read", "id": 2], to: input) else { return nil }
                } else if identifier == 2, initialized, let result = message["result"] as? [String: Any],
                          let data = try? JSONSerialization.data(withJSONObject: result) {
                    return try? ResetCredits.decode(data)
                }
            }
        }
        return nil
    }
}
