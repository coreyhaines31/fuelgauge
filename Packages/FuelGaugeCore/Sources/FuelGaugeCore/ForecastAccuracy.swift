import Foundation

public struct ForecastAccuracy: Sendable {
    public static let requiredPairs = 20
    public static let requiredDays = 3
    public let hours: Int
    public private(set) var paired = 0
    public private(set) var pairedDays = 0
    public private(set) var scheduledPairs = 0
    public private(set) var observed = 0
    public private(set) var adaptiveAvailable = 0
    public private(set) var recentAvailable = 0
    public private(set) var pending = 0
    public private(set) var missing = 0
    public private(set) var changed = 0
    public private(set) var unreliable = 0
    public private(set) var beyondReset = 0
    private var adaptiveError = 0.0
    private var recentError = 0.0

    public init(hours: Int) { self.hours = hours }

    public var hasEnoughEvidence: Bool { paired >= Self.requiredPairs && pairedDays >= Self.requiredDays }
    public var adaptiveMAE: Double? { hasEnoughEvidence ? adaptiveError / Double(paired) : nil }
    public var recentMAE: Double? { hasEnoughEvidence ? recentError / Double(paired) : nil }

    /// Compare the two methods on identical outcomes; abstentions never count as correct forecasts.
    public static func summarize(_ journal: ForecastJournal, key: LimitKey, now: Date,
                                 calendar: Calendar = .current) -> [Self] {
        let records = journal.records.filter {
            $0.source.key == key && $0.issuedAt >= now.addingTimeInterval(-30 * 86400) && $0.issuedAt <= now
        }
        return [1, 6, 24].map { hours in
            var result = Self(hours: hours)
            var days: Set<Date> = []
            for record in records {
                guard let target = record.targets.first(where: { $0.hours == hours }) else { continue }
                if result.include(target, scheduled: record.basis == "schedule") {
                    days.insert(calendar.startOfDay(for: record.issuedAt))
                }
            }
            result.pairedDays = days.count
            return result
        }
    }

    private mutating func include(_ target: ForecastRecord.Target, scheduled: Bool) -> Bool {
        switch target.outcome {
        case .pending: pending += 1
        case .missing: missing += 1
        case .changed: changed += 1
        case .unreliable: unreliable += 1
        case .beyondReset: beyondReset += 1
        case .observed: return compare(target, scheduled: scheduled)
        }
        return false
    }

    private mutating func compare(_ target: ForecastRecord.Target, scheduled: Bool) -> Bool {
        guard let actual = target.actual else { return false }
        observed += 1
        let adaptive = target.adaptive?.usage(at: actual.at, target: target.at)
        let recent = target.recent?.usage(at: actual.at, target: target.at)
        if adaptive != nil { adaptiveAvailable += 1 }
        if recent != nil { recentAvailable += 1 }
        guard let adaptive, let recent else { return false }
        paired += 1
        if scheduled { scheduledPairs += 1 }
        adaptiveError += abs(adaptive - actual.usedPercent)
        recentError += abs(recent - actual.usedPercent)
        return true
    }
}
