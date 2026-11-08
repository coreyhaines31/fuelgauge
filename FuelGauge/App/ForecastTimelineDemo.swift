#if DEBUG
import Foundation
import FuelGaugeCore
import SwiftUI

@MainActor
enum ForecastTimelineDemo {
    static func save(next url: URL) {
        let now = Date()
        let key = LimitKey(provider: .codex, limit: "weekly")
        let journal = ForecastDemo.journal(now: now, skipping: [-22, -21, -8])
        let history = ForecastComparison.history(journal, key: key, now: now)
        let observed = history.filter { $0.target.hours == 6 && $0.actual != nil }
            .max { abs($0.error ?? 0) < abs($1.error ?? 0) }
        let missing = history.first { $0.target.hours == 1 && $0.target.outcome == .missing }
        let pending = history.last { $0.target.hours == 24 && $0.target.outcome == .pending }
        for (name, hours, selected) in [("timeline", 6, observed), ("missed", 1, missing), ("pending", 24, pending)] {
            DemoMode.render(ForecastTimelineView(history: history, now: now, hours: hours, selectedID: selected?.id)
                .padding(20).frame(width: 700),
                to: url.deletingPathExtension().appendingPathExtension("\(name).png"))
        }
        let sparse = Array(history.filter { $0.target.hours == 1 }.suffix(2))
        DemoMode.render(ForecastTimelineView(history: sparse, now: now).padding(20).frame(width: 644),
                        to: url.deletingPathExtension().appendingPathExtension("timeline-sparse.png"))
        DemoMode.render(ForecastTimelineView(history: [], now: now).padding(20).frame(width: 644),
                        to: url.deletingPathExtension().appendingPathExtension("timeline-empty.png"))
    }
}
#endif
