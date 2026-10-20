import Foundation

/// The command Claude Code runs for its status line. It points at the `fuelgauge` command on the PATH when
/// Homebrew linked it there, else at the copy inside this app, so it keeps working after updates.
enum StatusLineCommand {
    private static let linked = ["/opt/homebrew/bin/fuelgauge", "/usr/local/bin/fuelgauge"]

    static func invocation() -> String {
        if let path = linked.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return "\(path) statusline"
        }
        let bundled = Bundle.main.url(forAuxiliaryExecutable: "fuelgauge")?.path
            ?? "/Applications/Fuel Gauge.app/Contents/MacOS/fuelgauge"
        return "'\(bundled.replacingOccurrences(of: "'", with: "'\\''"))' statusline"
    }
}
