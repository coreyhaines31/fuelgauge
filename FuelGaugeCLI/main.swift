import Foundation
import FuelGaugeCore

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.first == "--version" {
    print(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
    exit(0)
}
print("fuelgauge: forecast when you'll hit your Claude Code and Codex limits. Coming soon.")
