#if DEBUG
import Foundation
import FuelGaugeCore

enum ForecastDemo {
    static func burstReadings(now: Date) -> [Reading] {
        var previous: Reading?
        var used = 0.0
        return readings(now: now).filter { $0.provider == .codex }.map { reading in
            if let previous, previous.resetsAt == reading.resetsAt {
                let scale = previous.at >= now.addingTimeInterval(-3 * 86400) ? 0.5 : 0.01
                used += max(0, reading.usedPercent - previous.usedPercent) * scale
            } else {
                used = 0
            }
            previous = reading
            var result = reading
            result.usedPercent = used
            return result
        }
    }

    static func sparseReadings(now: Date) -> [Reading] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -21, to: calendar.startOfDay(for: now))!
        return (0...21).flatMap { day -> [Reading] in
            let date = calendar.date(byAdding: .day, value: day, to: start)!
            guard !calendar.isDateInWeekend(date) else { return [] }
            return (9...21).map { hour in
                Reading(provider: .codex, limit: "weekly", windowMinutes: 10080,
                        usedPercent: Double(day % 7) * 10 + Double(hour - 9) * 0.5,
                        resetsAt: calendar.date(byAdding: .day, value: (day / 7 + 1) * 7, to: start)!,
                        at: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!)
            }.filter { $0.at <= now }
        }
    }

    static func journal(now: Date) -> ForecastJournal {
        let data = readings(now: now)
        var journal = ForecastJournal()
        for hour in -72...0 {
            let at = now.addingTimeInterval(Double(hour) * 3600)
            let history = data.filter { $0.at <= at }
            journal.update(forecasts: ForecastEngine.forecasts(from: history, now: at),
                           readings: history, now: at, appVersion: "demo")
        }
        return journal
    }

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
