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
