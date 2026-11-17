import Foundation
@testable import FuelGaugeCore

enum ForecastSamples {
    static let start = Date(timeIntervalSince1970: 1_788_739_200)

    static func weekdays(until now: Date, mondayRate: Double = 1.75) -> [Reading] {
        var used = 0.0
        var readings: [Reading] = []
        let steps = Int(now.timeIntervalSince(start) / 900)
        for step in 0...steps {
            let at = start.addingTimeInterval(Double(step) * 900)
            let week = min(3, step / (7 * 24 * 4))
            if step < 28 * 24 * 4 && step % (7 * 24 * 4) == 0 { used = 0 }
            let resets = start.addingTimeInterval(Double((week + 1) * 7 * 24 + (week == 3 ? 18 : 0)) * 3600)
            readings.append(Reading(provider: .codex, limit: "weekly", windowMinutes: 10080,
                                    usedPercent: min(100, used), resetsAt: resets, at: at))
            let busy = !Calendar.utc.isDateInWeekend(at)
                && (9..<17).contains(Calendar.utc.component(.hour, from: at))
            let rate = step >= 28 * 24 * 4 ? mondayRate : (week == 3 ? 1.75 : 1.5)
            if busy { used += rate / 4 }
        }
        return readings
    }
}
