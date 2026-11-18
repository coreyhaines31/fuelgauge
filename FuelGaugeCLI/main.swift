import Foundation
import FuelGaugeCore

let usage = """
fuelgauge: will your Claude Code, Codex, and Grok Bot limits last until they reset?

Usage:
  fuelgauge status [--json]
  fuelgauge resets [--json]
  fuelgauge history [--days 1] [--json]
  fuelgauge backtest [--days 7] [--json]
  fuelgauge statusline
  fuelgauge install-statusline
  fuelgauge uninstall-statusline

Commands:
  status                Each limit: percent used, when it resets, and whether it lasts until then.
                        Exits 2 when a limit is forecast to run out before it resets, or already has.
  resets                Each Claude account's recorded Fable and weekly resets, its Fable allowance,
                        and which reset would help if the week won't last. With --json, the account
                        in CLAUDE_CONFIG_DIR, else the default one. Read-only: it never uses a reset.
  history               The readings behind the forecasts, per limit.
  backtest              Compare recent and adaptive forecasts against saved observations. Read-only.
  statusline            Claude Code's status line command: reads Claude's limits from stdin, saves
                        them, and prints the forecast. Set up with install-statusline.
  install-statusline    Make Fuel Gauge Claude Code's status line. An existing status line keeps
                        showing, above the forecast. Backs up settings.json first.
  uninstall-statusline  Put Claude Code's status line back the way it was.

Several accounts: Claude Code keeps each sign-in in its own folder (CLAUDE_CONFIG_DIR=~/.claude-work
claude). Run install-statusline once per account, with that account's CLAUDE_CONFIG_DIR set, or turn it
on in Fuel Gauge's Settings › Tools. Each account's readings stay its own.

For agents: run `fuelgauge status` before a long task. If it exits 2, tell the person which limit
runs out and when, and ask before starting, or switch to a cheaper model.
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("fuelgauge: \(message)\n".utf8))
    exit(1)
}

// A wrapped status line command that exits without reading its input would otherwise kill this process
// with SIGPIPE when the input is written, blanking Claude Code's status line.
signal(SIGPIPE, SIG_IGN)

let arguments = Array(CommandLine.arguments.dropFirst())
let wantsJSON = arguments.contains("--json")
let store = ReadingStore()
// The command's own CLAUDE_CONFIG_DIR names the account it runs for, so it never decides the default folder.
let accounts = AccountList.load(environment: [:])

/// The Claude Code account this command runs for: the one its `CLAUDE_CONFIG_DIR` points at, else the default.
func currentClaudeAccount() -> Account {
    accounts.account(.claude, environment: ProcessInfo.processInfo.environment)
        ?? Account.defaultAccount(.claude, environment: [:])
}

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
    // Tracked accounts only, named when a tool has several.
    let readings = store.load(since: now.addingTimeInterval(-ForecastEngine.historyDuration)).filter {
        enabled.contains($0.provider) && (!Account.multiAccountProviders.contains($0.provider)
            || accounts.account($0.provider, slug: $0.account) != nil)
    }
    return accounts.label(ForecastEngine.forecasts(from: readings, now: now).filter {
        !($0.verdict == .reset && $0.resetsAt < now.addingTimeInterval(-24 * 3600))
    })
}

func status() -> Never {
    let now = Date()
    let forecasts = currentForecasts(now: now)
    if wantsJSON {
        guard let data = try? ForecastJSON.encode(forecasts, now: now) else { fail("couldn't encode the forecast") }
        FileHandle.standardOutput.write(data + Data("\n".utf8))
    } else if forecasts.isEmpty {
        print("No readings yet. Open Fuel Gauge, and use Claude Code, Codex, or Grok Bot for a few minutes.")
        if Tracking.isEnabled(.claude), ClaudeSettings(account: currentClaudeAccount()).state != .on {
            print("For Claude Code limits, run: fuelgauge install-statusline")
        }
    } else {
        for forecast in forecasts {
            let name = "\(forecast.sourceLabel) · \(forecast.windowName)"
            print("\(name): \(ForecastText.headline(forecast, now: now))")
            print("  \(ForecastText.usage(forecast, now: now))")
            if let pace = ForecastText.pace(forecast) { print("  \(pace)") }
            if let scenario = ForecastText.sessionScenario(forecast, now: now) { print("  \(scenario)") }
            if let range = ForecastText.range(forecast, now: now) { print("  \(range)") }
            if let share = modelShare(forecast, now: now) { print("  \(share)") }
        }
        if Tracking.isEnabled(.claude) { printResets(forecasts: forecasts, now: now, headerOnlyIfAny: true) }
    }
    exit(forecasts.contains(where: \.isShort) ? 2 : 0)
}

/// The app's last Fable check for an account.
func claudeUsage(_ account: Account) -> ClaudeUsage? {
    ClaudeUsage.load(from: ClaudeUsage.url(for: account))
}

/// "18% of your week so far · up to 50%" for a model allowance, from the app's last check.
func modelShare(_ forecast: Forecast, now: Date) -> String? {
    guard let name = forecast.modelName,
          let account = accounts.account(forecast.key.provider, slug: forecast.key.account),
          let allowance = claudeUsage(account)?.model(named: name),
          allowance.resetsAt > now, let used = allowance.usedPercentOfWeekly else { return nil }
    let cap = allowance.allowancePercentOfWeekly.map { " · up to \(ForecastText.percent($0))" } ?? ""
    return "\(ForecastText.percent(used)) of your week so far\(cap)"
}

/// Each Claude account's recorded resets and the planner's suggestion, as text.
func printResets(forecasts: [Forecast], now: Date, headerOnlyIfAny: Bool) {
    for account in accounts.accounts(for: .claude) {
        let own = forecasts.filter { $0.key.provider == .claude && $0.key.account == account.slug }
        let label = accounts.label(provider: .claude, slug: account.slug).map { "Claude Code · \($0)" }
        printResets(account, label: label ?? "Claude Code", forecasts: own, now: now, headerOnlyIfAny: headerOnlyIfAny)
    }
}

func printResets(_ account: Account, label: String, forecasts: [Forecast], now: Date, headerOnlyIfAny: Bool) {
    let resets = ClaudeResets.load(account: account)
    let advice = ResetAdvice.suggest(forecasts: forecasts, usage: claudeUsage(account), resets: resets, now: now)
    guard let recorded = resets.recordedAt else {
        if let advice { print("\(label) · \(advice.title)\n  \(advice.text)") }
        if !headerOnlyIfAny {
            print("\(label): no resets recorded. Record them in Fuel Gauge's Settings › Resets.")
        }
        return
    }
    print("\(label) · Resets (recorded by hand \(ForecastText.time(recorded, now: now)))")
    for kind in ClaudeResets.Kind.allCases {
        let expiry = resets.expiry(kind, now: now).map { ". \($0)" } ?? ""
        print("  \(resets.summary(kind, now: now)): \(kind.explanation)\(expiry)")
    }
    if let advice { print("  \(advice.title). \(advice.text)") }
}

func resetsCommand() -> Never {
    let now = Date()
    let forecasts = currentForecasts(now: now)
    if wantsJSON {
        // The default account, or the one CLAUDE_CONFIG_DIR points at.
        let account = currentClaudeAccount()
        let resets = ClaudeResets.load(account: account)
        let own = forecasts.filter { $0.key.provider == .claude && $0.key.account == account.slug }
        // Claude Code turned off in Fuel Gauge: the recorded counts, but no allowance or advice.
        let usage = Tracking.isEnabled(.claude) ? claudeUsage(account) : nil
        let advice = Tracking.isEnabled(.claude)
            ? ResetAdvice.suggest(forecasts: own, usage: usage, resets: resets, now: now) : nil
        guard let data = try? ResetsJSON.encode(ResetsJSON(resets: resets, usage: usage, advice: advice, now: now))
        else { fail("couldn't encode the resets") }
        FileHandle.standardOutput.write(data + Data("\n".utf8))
    } else {
        printResets(forecasts: forecasts, now: now, headerOnlyIfAny: false)
    }
    exit(0)
}

func history() -> Never {
    let days = Double(option("--days") ?? "1") ?? 1
    let readings = store.load(since: Date().addingTimeInterval(-days * 86400))
    if wantsJSON {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        for reading in readings {
            var line: [String: String] = [
                "tool": reading.provider.rawValue,
                "limit": reading.limit, "at": reading.at.ISO8601Format(),
                "used_percent": String(reading.usedPercent), "resets_at": reading.resetsAt.ISO8601Format()
            ]
            if let account = reading.account { line["account"] = account }
            if let data = try? encoder.encode(line), let text = String(bytes: data, encoding: .utf8) { print(text) }
        }
    } else {
        for (key, group) in Dictionary(grouping: readings, by: \.key).sorted(by: { $0.key < $1.key }) {
            let window = WindowName.of(windowMinutes: group.last?.windowMinutes)
            let name = ModelLimit.modelName(of: key.limit).map { "\($0) \(window.lowercased())" } ?? window
            // An account that isn't added in Fuel Gauge yet still shows apart, by its slug.
            let source = (accounts.label(provider: key.provider, slug: key.account) ?? key.account)
                .map { "\(key.provider.name) · \($0)" } ?? key.provider.name
            print("\(source) · \(name)")
            for reading in group {
                print("  \(ForecastText.time(reading.at))  \(ForecastText.percent(reading.usedPercent))")
            }
        }
    }
    exit(0)
}

let nestedStatusLineKey = "FUEL_GAUGE_NESTED_STATUSLINE"

/// Claude Code's status line: save the reading, print any wrapped status line, then the forecast strip.
/// Never fails loudly, since anything on stderr is lost and a crash blanks the status line.
func statusLine() -> Never {
    let input = FileHandle.standardInput.readDataToEndOfFile()
    let now = Date()
    let account = currentClaudeAccount()
    let settings = ClaudeSettings(account: account)
    // A wrapped command that leads back here (directly or through another tool's wrapper) would spawn
    // status lines forever, so a nested run skips it.
    let nested = ProcessInfo.processInfo.environment[nestedStatusLineKey] != nil
    if !nested, let wrapped = settings.wrappedCommand, let output = run(wrapped, input: input) {
        print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
    }
    guard Tracking.isEnabled(.claude) else { exit(0) }
    try? store.append(ClaudeStatusLine.readings(from: input, at: now, account: account.slug), now: now)
    // Only this session's account: another account's limits say nothing about this one.
    let readings = store.load(since: now.addingTimeInterval(-ForecastEngine.historyDuration), provider: .claude)
        .filter { $0.account == account.slug }
    let forecasts = ForecastEngine.forecasts(from: readings, now: now).filter { $0.verdict != .reset }
    if let strip = StatusLineStrip.render(forecasts, now: now) {
        print(strip)
    }
    exit(0)
}

/// Runs the status line command Fuel Gauge replaced, with the same input, for up to 3 seconds. It runs in
/// its own process group, so a timeout stops everything it started, not just the shell.
func run(_ command: String, input: Data) -> String? {
    var stdinPipe: [Int32] = [0, 0]
    var stdoutPipe: [Int32] = [0, 0]
    guard pipe(&stdinPipe) == 0, pipe(&stdoutPipe) == 0 else { return nil }
    var actions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&actions)
    defer { posix_spawn_file_actions_destroy(&actions) }
    posix_spawn_file_actions_adddup2(&actions, stdinPipe[0], STDIN_FILENO)
    posix_spawn_file_actions_adddup2(&actions, stdoutPipe[1], STDOUT_FILENO)
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0)
    for descriptor in stdinPipe + stdoutPipe { posix_spawn_file_actions_addclose(&actions, descriptor) }
    var attributes: posix_spawnattr_t?
    posix_spawnattr_init(&attributes)
    defer { posix_spawnattr_destroy(&attributes) }
    posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP))
    posix_spawnattr_setpgroup(&attributes, 0)

    var pid: pid_t = 0
    let argv: [UnsafeMutablePointer<CChar>?] = [strdup("/bin/sh"), strdup("-c"), strdup(command), nil]
    defer { argv.forEach { free($0) } }
    let envp = nestedEnvironment()
    defer { envp.forEach { free($0) } }
    let spawned = posix_spawn(&pid, "/bin/sh", &actions, &attributes, argv, envp)
    close(stdinPipe[0])
    close(stdoutPipe[1])
    guard spawned == 0 else {
        close(stdinPipe[1])
        close(stdoutPipe[0])
        return nil
    }

    // Write and read on other threads, so a command that ignores its input or prints a lot can't block
    // this one past the timeout.
    let writer = FileHandle(fileDescriptor: stdinPipe[1], closeOnDealloc: true)
    DispatchQueue.global().async {
        try? writer.write(contentsOf: input)
        try? writer.close()
    }
    let output = OutputBox()
    let reader = FileHandle(fileDescriptor: stdoutPipe[0], closeOnDealloc: true)
    let done = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
        output.data = (try? reader.readToEnd()) ?? Data()
        done.signal()
    }
    let timedOut = done.wait(timeout: .now() + 3) == .timedOut
    if timedOut {
        kill(-pid, SIGTERM)
        usleep(200_000)
        kill(-pid, SIGKILL)
    }
    var status: Int32 = 0
    waitpid(pid, &status, 0)
    if timedOut { return nil }
    return output.data.isEmpty ? nil : String(bytes: output.data, encoding: .utf8)
}

/// This process's environment, marked so a `fuelgauge statusline` started inside it knows it's nested.
func nestedEnvironment() -> [UnsafeMutablePointer<CChar>?] {
    var environment = ProcessInfo.processInfo.environment
    environment[nestedStatusLineKey] = "1"
    return environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
}

final class OutputBox: @unchecked Sendable {
    var data = Data()
}

func installStatusLine() -> Never {
    let settings = ClaudeSettings(account: currentClaudeAccount())
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
    let settings = ClaudeSettings(account: currentClaudeAccount())
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
case "resets":
    resetsCommand()
case "history":
    history()
case "backtest":
    backtest()
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
