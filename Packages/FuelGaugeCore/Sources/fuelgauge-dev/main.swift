import Foundation
import FuelGaugeCore

let start = Date()
var codex = CodexLogReader()
let codexReadings = codex.poll()
print("Codex: \(codexReadings.count) readings in \(String(format: "%.2f", Date().timeIntervalSince(start)))s")
for (key, readings) in Dictionary(grouping: codexReadings, by: \.key).sorted(by: { $0.key < $1.key }) {
    guard let last = readings.max(by: { $0.at < $1.at }) else { continue }
    print("  \(key.id): \(readings.count) readings, now \(last.usedPercent)%, resets \(last.resetsAt)")
}
for reading in GrokBotReader().read() {
    print("Grok Bot: \(reading.usedPercent)% at \(reading.at), resets \(reading.resetsAt)")
}
print("Claude status line: \(ClaudeSettings().state)")

print("\nForecasts:")
for forecast in ForecastEngine.forecasts(from: codexReadings + GrokBotReader().read()) {
    print("  \(forecast.key.provider.name) \(forecast.windowName): \(ForecastText.headline(forecast))")
    print("    \(ForecastText.usage(forecast))")
    if let pace = ForecastText.pace(forecast) { print("    \(pace)") }
    if let range = ForecastText.range(forecast) { print("    \(range)") }
}

if CommandLine.arguments.contains("--cursor") {
    for reading in await CursorReader().read() {
        print("Cursor: \(reading.usedPercent)% of the monthly plan, resets \(reading.resetsAt)")
    }
}
