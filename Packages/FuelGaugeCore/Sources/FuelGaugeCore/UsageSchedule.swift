import Foundation

/// Hourly weekday/weekend averages learned only from observed intervals, with a two-week half-life.
struct UsageSchedule {
    private struct Bucket {
        var consumed = 0.0
        var weight = 0.0
        var hours = 0.0
        var days: Set<Date> = []

        mutating func add(rate: Double, hours: Double, day: Date, weight: Double) {
            consumed += rate * hours * weight
            self.weight += hours * weight
            self.hours += hours
            days.insert(day)
        }

        var supported: Bool { days.count >= 2 && hours >= 2 }
        var rate: Double { weight > 0 ? consumed / weight : 0 }
    }

    private var buckets = Array(repeating: Bucket(), count: 48)
    private var pooled = Array(repeating: Bucket(), count: 24)
    private let calendar: Calendar
    private(set) var observedDays = 0
    private(set) var recentMultiplier = 1.0
    private(set) var evidence = ScheduleEvidence(ageDays: 0, observedHours: 0, observedDays: 0, supportedHours: 0)

    init?(_ intervals: [ReadingTimeline.Interval], now: Date, calendar: Calendar) {
        self.init(observing: intervals, now: now, calendar: calendar)
        if !evidence.isReady { return nil }
    }

    init(observing intervals: [ReadingTimeline.Interval], now: Date, calendar: Calendar) {
        self.calendar = calendar
        let cutoff = now.addingTimeInterval(-14 * 86400)
        let knownHours = intervals.reduce(0.0) { total, interval in
            total + max(0, interval.end.timeIntervalSince(max(interval.start, cutoff))) / 3600
        }
        var days: Set<Date> = []
        for interval in intervals {
            var start = interval.start
            while start < interval.end {
                let hour = calendar.dateInterval(of: .hour, for: start)!
                let end = min(interval.end, hour.end)
                let hours = end.timeIntervalSince(start) / 3600
                let day = calendar.startOfDay(for: start)
                let weight = pow(0.5, max(0, now.timeIntervalSince(end)) / (14 * 86400))
                let rate = interval.consumed / interval.hours
                buckets[index(at: start)].add(rate: rate, hours: hours, day: day, weight: weight)
                pooled[calendar.component(.hour, from: start)].add(rate: rate, hours: hours, day: day, weight: weight)
                days.insert(day)
                start = end
            }
        }
        observedDays = days.count
        evidence = ScheduleEvidence(ageDays: intervals.first.map { now.timeIntervalSince($0.start) / 86400 } ?? 0,
                                    observedHours: knownHours, observedDays: days.count,
                                    supportedHours: pooled.filter(\.supported).count)
        if evidence.isReady { recentMultiplier = trend(intervals, now: now) }
    }

    func rate(at date: Date) -> Double? {
        let bucket = buckets[index(at: date)]
        if bucket.supported { return bucket.rate }
        let pool = pooled[calendar.component(.hour, from: date)]
        return pool.supported ? pool.rate : nil
    }

    private func index(at date: Date) -> Int {
        calendar.component(.hour, from: date) + (calendar.isDateInWeekend(date) ? 24 : 0)
    }

    private func trend(_ intervals: [ReadingTimeline.Interval], now: Date) -> Double {
        var actual = 0.0
        var expected = 0.0
        var coverage = 0.0
        let cutoff = now.addingTimeInterval(-3 * 86400)
        for interval in intervals where interval.start >= cutoff {
            var start = interval.start
            while start < interval.end {
                let end = min(interval.end, calendar.dateInterval(of: .hour, for: start)!.end)
                let hours = end.timeIntervalSince(start) / 3600
                if let expectedRate = rate(at: start) {
                    actual += interval.consumed * hours / interval.hours
                    expected += expectedRate * hours
                    coverage += hours
                }
                start = end
            }
        }
        guard coverage >= 12, expected >= 1 else { return 1 }
        return min(2, max(0.5, actual / expected))
    }
}
