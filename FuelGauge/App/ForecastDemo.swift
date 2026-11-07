#if DEBUG
import Foundation
import FuelGaugeCore

enum ForecastDemo {
    static func readings(now: Date) -> [Reading] {
        let start = now.addingTimeInterval(-28 * 86400)
        let currentStart = now.addingTimeInterval(-4 * 86400)
        var previousWeek = -10
        var used = 0.0
        var result: [Reading] = []
        for hour in 0...(28 * 24) {
            let at = start.addingTimeInterval(Double(hour) * 3600)
            let week = Int(floor(at.timeIntervalSince(currentStart) / (7 * 86400)))
            if week != previousWeek {
                used = week == 0 ? 55 : 0
                previousWeek = week
            }
            result.append(Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: used,
                                  resetsAt: currentStart.addingTimeInterval(Double(week + 1) * 7 * 86400), at: at))
            if !Calendar.current.isDateInWeekend(at), (9..<17).contains(Calendar.current.component(.hour, from: at)) {
                used = min(100, used + 1.25)
            }
        }
        for (hours, percent) in [(6.0, 71.0), (1.0, 71.0), (0.5, 73.5), (0.0, 76.0)] {
            result.append(Reading(provider: .claude, limit: "weekly", windowMinutes: 10080, usedPercent: percent,
                                  resetsAt: now.addingTimeInterval(24 * 3600),
                                  at: now.addingTimeInterval(-hours * 3600)))
        }
        result.append(Reading(provider: .grokBot, limit: "weekly", windowMinutes: 10080, usedPercent: 12,
                              resetsAt: now.addingTimeInterval(72 * 3600), at: now.addingTimeInterval(-8 * 3600)))
        return result
    }
}
#endif
