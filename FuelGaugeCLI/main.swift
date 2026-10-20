import Foundation
import FuelGaugeCore

let usage = """
fuelgauge: will your Claude Code, Codex, and Grok Bot limits last until they reset?

Usage:
  fuelgauge status [--json]
  fuelgauge history [--days 1] [--json]
  fuelgauge statusline
  fuelgauge install-statusline
  fuelgauge uninstall-statusline

Commands:
  status                Each limit: percent used, when it resets, and whether it lasts until then.
                        Exits 2 when a limit is forecast to run out before it resets, or already has.
  history               The readings behind the forecasts, per limit.
  statusline            Claude Code's status line command: reads Claude's limits from stdin, saves
                        them, and prints the forecast. Set up with install-statusline.
  install-statusline    Make Fuel Gauge Claude Code's status line. An existing status line keeps
                        showing, above the forecast. Backs up settings.json first.
  uninstall-statusline  Put Claude Code's status line back the way it was.

For agents: run `fuelgauge status` before a long task. If it exits 2, tell the person which limit
runs out and when, and ask before starting, or switch to a cheaper model.
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("fuelgauge: \(message)\n".utf8))
    exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let wantsJSON = arguments.contains("--json")
let store = ReadingStore()

func option(_ name: String) -> String? {
    guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
}

/// Forecasts for the tracked tools, from saved readings plus a fresh look at Grok Bot's cache.
func currentForecasts(now: Date = Date()) -> [Forecast] {
    let enabled = Tracking.enabled()
    if enabled.contains(.grokBot) {
        try? store.append(GrokBotReader().read(), now: now)
    }
    let readings = store.load(since: now.addingTimeInterval(-8 * 24 * 3600))
        .filter { enabled.contains($0.provider) }
    return ForecastEngine.forecasts(from: readings, now: now).filter {
        !($0.verdict == .reset && $0.resetsAt < now.addingTimeInterval(-24 * 3600))
    }
}

func status() -> Never {
    let now = Date()
    let forecasts = currentForecasts(now: now)
    if wantsJSON {
        guard let data = try? ForecastJSON.encode(forecasts, now: now) else { fail("couldn't encode the forecast") }
        FileHandle.standardOutput.write(data + Data("\n".utf8))
    } else if forecasts.isEmpty {
        print("No readings yet. Open Fuel Gauge, and use Claude Code, Codex, or Grok Bot for a few minutes.")
        if Tracking.isEnabled(.claude), ClaudeSettings().state != .on {
            print("For Claude Code limits, run: fuelgauge install-statusline")
        }
    } else {
        for forecast in forecasts {
            let name = "\(forecast.key.provider.name) · \(forecast.windowName)"
            print("\(name): \(ForecastText.headline(forecast, now: now))")
            print("  \(ForecastText.usage(forecast, now: now))")
            if let pace = ForecastText.pace(forecast) { print("  \(pace)") }
            if let range = ForecastText.range(forecast, now: now) { print("  \(range)") }
        }
    }
    exit(forecasts.contains(where: \.isShort) ? 2 : 0)
}

func history() -> Never {
    let days = Double(option("--days") ?? "1") ?? 1
    let readings = store.load(since: Date().addingTimeInterval(-days * 86400))
    if wantsJSON {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        for reading in readings {
            let line: [String: String] = [
                "tool": reading.provider.rawValue, "limit": reading.limit, "at": reading.at.ISO8601Format(),
                "used_percent": String(reading.usedPercent), "resets_at": reading.resetsAt.ISO8601Format()
            ]
            if let data = try? encoder.encode(line), let text = String(bytes: data, encoding: .utf8) { print(text) }
        }
    } else {
        for (key, group) in Dictionary(grouping: readings, by: \.key).sorted(by: { $0.key < $1.key }) {
            print("\(key.provider.name) · \(WindowName.of(windowMinutes: group.last?.windowMinutes))")
            for reading in group {
                print("  \(ForecastText.time(reading.at))  \(ForecastText.percent(reading.usedPercent))")
            }
        }
    }
    exit(0)
}

/// Claude Code's status line: save the reading, print any wrapped status line, then the forecast strip.
/// Never fails loudly, since anything on stderr is lost and a crash blanks the status line.
func statusLine() -> Never {
    let input = FileHandle.standardInput.readDataToEndOfFile()
    let now = Date()
    let settings = ClaudeSettings()
    if let wrapped = settings.wrappedCommand, let output = run(wrapped, input: input) {
        print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
    }
    guard Tracking.isEnabled(.claude) else { exit(0) }
    try? store.append(ClaudeStatusLine.readings(from: input, at: now), now: now)
    let readings = store.load(since: now.addingTimeInterval(-8 * 24 * 3600), provider: .claude)
    let forecasts = ForecastEngine.forecasts(from: readings, now: now).filter { $0.verdict != .reset }
    if let strip = StatusLineStrip.render(forecasts, now: now) {
        print(strip)
    }
    exit(0)
}

/// Runs the status line command Fuel Gauge replaced, with the same input, for up to 3 seconds.
func run(_ command: String, input: Data) -> String? {
    let process = Process()
    process.executableURL = URL(filePath: "/bin/sh")
    process.arguments = ["-c", command]
    let stdin = Pipe()
    let stdout = Pipe()
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    stdin.fileHandleForWriting.write(input)
    try? stdin.fileHandleForWriting.close()
    let deadline = Date().addingTimeInterval(3)
    while process.isRunning && Date() < deadline { usleep(10_000) }
    if process.isRunning { process.terminate() }
    let data = stdout.fileHandleForReading.readDataToEndOfFile()
    return data.isEmpty ? nil : String(bytes: data, encoding: .utf8)
}

func installStatusLine() -> Never {
    let settings = ClaudeSettings()
    let path = Bundle.main.executableURL?.resolvingSymlinksInPath().path ?? "fuelgauge"
    let linked = ["/opt/homebrew/bin/fuelgauge", "/usr/local/bin/fuelgauge"].first {
        URL(filePath: $0).resolvingSymlinksInPath().path == path
    }
    let command = (linked ?? "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'") + " statusline"
    do {
        try settings.install(command: command)
    } catch {
        fail("couldn't update \(settings.settingsURL.path): \(error.localizedDescription)")
    }
    print("Claude Code's status line now shows the forecast. It appears after Claude's next reply.")
    if let wrapped = settings.wrappedCommand {
        print("Your existing status line (\(wrapped)) keeps showing above it.")
    }
    exit(0)
}

func uninstallStatusLine() -> Never {
    let settings = ClaudeSettings()
    do {
        try settings.uninstall()
    } catch {
        fail("couldn't update \(settings.settingsURL.path): \(error.localizedDescription)")
    }
    print("Fuel Gauge is no longer Claude Code's status line.")
    exit(0)
}

switch arguments.first {
case "--version", "version":
    print(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
case "status", nil:
    status()
case "history":
    history()
case "statusline":
    statusLine()
case "install-statusline":
    installStatusLine()
case "uninstall-statusline":
    uninstallStatusLine()
case "--help", "-h", "help":
    print(usage)
default:
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(1)
}
