#if DEBUG
import Foundation
import FuelGaugeCore
import SwiftUI

@MainActor
enum SessionPlanDemo {
    private struct Sample {
        let name: String
        let readings: [Reading]
        var minutes = 120
    }

    static func save(next url: URL) {
        let now = Date()
        let short = readings(now: now, minutes: 300, used: 40, rate: 20, resetIn: 4)
        let weekly = readings(now: now, minutes: 10080, used: 40, rate: 8, resetIn: 72)
        let cases: [Sample] = [
            .init(name: "session-safe", readings: short + weekly),
            .init(name: "session-short", readings: short + weekly, minutes: 240),
            .init(name: "session-weekly", readings: short
                + readings(now: now, minutes: 10080, used: 80, rate: 15, resetIn: 72)),
            .init(name: "session-reset", readings: weekly
                + readings(now: now, minutes: 300, used: 40, rate: 20, resetIn: 0.75)),
            .init(name: "session-unknown", readings: short
                + readings(now: now, minutes: 10080, used: 40, rate: 0, resetIn: 72)),
            .init(name: "session-stale", readings: weekly
                + readings(now: now, minutes: 300, used: 40, rate: 20, resetIn: 4, age: 2), minutes: 30)
        ]
        for sample in cases {
            let forecasts = ForecastEngine.forecasts(from: sample.readings, now: now)
            DemoMode.render(SessionPlanView(forecasts: forecasts, now: now, minutes: sample.minutes)
                .padding(20).frame(width: 644),
                to: url.deletingPathExtension().appendingPathExtension("\(sample.name).png"))
        }
    }

    private static func readings(now: Date, minutes: Int, used: Double, rate: Double,
                                 resetIn hours: Double, age: Double = 0) -> [Reading] {
        [1.0, 0.5, 0].map { ago in
            Reading(provider: .codex, limit: "\(minutes)", windowMinutes: minutes,
                    usedPercent: used - rate * ago, resetsAt: now.addingTimeInterval(hours * 3600),
                    at: now.addingTimeInterval(-(ago + age) * 3600))
        }
    }
}
#endif
