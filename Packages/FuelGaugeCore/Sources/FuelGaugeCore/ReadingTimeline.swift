import Foundation

/// Reconciles one limit without changing its saved readings. A lower report must persist before it
/// replaces a higher one; otherwise alternating session caches look like repeated consumption.
struct ReadingTimeline {
    var segments: [[Reading]] = []
    var hasConflict = false

    init(_ readings: [Reading], now: Date) {
        let valid = readings.filter {
            $0.at <= now && $0.usedPercent.isFinite && $0.usedPercent >= 0
                && ($0.windowMinutes.map { $0 > 0 } ?? true)
        }.sorted { $0.at == $1.at ? $0.usedPercent > $1.usedPercent : $0.at < $1.at }
        var lowerSince: Date?
        for var reading in valid {
            reading.usedPercent = min(100, reading.usedPercent)
            guard let previous = segments.last?.last else {
                segments.append([reading])
                continue
            }
            guard reading.at > previous.at else { continue }
            if !Self.sameWindow(previous, reading) {
                segments.append([reading])
                lowerSince = nil
            } else if reading.usedPercent < previous.usedPercent {
                let since = lowerSince ?? reading.at
                lowerSince = since
                if reading.at.timeIntervalSince(since) >= 600 {
                    // A sustained correction or an unscheduled reset starts a new baseline.
                    segments.append([reading])
                    lowerSince = nil
                }
            } else {
                segments[segments.count - 1].append(reading)
                lowerSince = nil
            }
        }
        hasConflict = lowerSince != nil
    }

    static func sameWindow(_ lhs: Reading, _ rhs: Reading) -> Bool {
        lhs.key == rhs.key && lhs.windowMinutes == rhs.windowMinutes
            && abs(lhs.resetsAt.timeIntervalSince(rhs.resetsAt)) <= 600
    }

    struct Interval {
        let start: Date
        let end: Date
        let consumed: Double

        var hours: Double { end.timeIntervalSince(start) / 3600 }
    }

    var intervals: [Interval] {
        segments.flatMap { segment in
            zip(segment, segment.dropFirst()).compactMap { before, after in
                let elapsed = after.at.timeIntervalSince(before.at)
                let consumed = after.usedPercent - before.usedPercent
                // Equal endpoints establish inactivity. A rise across a long gap doesn't tell us
                // which hours were busy, and a capped quota doesn't establish inactivity either.
                guard before.usedPercent < 100, after.at <= before.resetsAt,
                      elapsed > 0, elapsed <= (consumed == 0 ? 48 : 3) * 3600 else { return nil }
                return Interval(start: before.at, end: after.at, consumed: consumed)
            }
        }
    }
}
