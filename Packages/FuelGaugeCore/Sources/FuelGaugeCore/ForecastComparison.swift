import Foundation

/// A saved forecast and its outcome, compared at the same source timestamp as the accuracy score.
public struct ForecastComparison: Identifiable, Sendable {
    public let record: ForecastRecord
    public let target: ForecastRecord.Target

    public var id: String { "\(record.source.key.id)|\(record.issuedAt.timeIntervalSince1970)|\(target.hours)" }
    public var actual: Reading? { target.outcome == .observed ? target.actual : nil }
    public var at: Date { actual?.at ?? target.at }
    public var predicted: Double? { target.adaptive?.usage(at: at, target: target.at) }
    public var recent: Double? { target.recent?.usage(at: at, target: target.at) }
    public var error: Double? {
        guard let predicted, let actual else { return nil }
        return predicted - actual.usedPercent
    }

    public static func history(_ journal: ForecastJournal, key: LimitKey, now: Date) -> [Self] {
        journal.records.filter {
            $0.source.key == key && $0.issuedAt >= now.addingTimeInterval(-30 * 86400) && $0.issuedAt <= now
        }.flatMap { record in
            record.targets.map { Self(record: record, target: $0) }
        }.sorted {
            if $0.at != $1.at { return $0.at < $1.at }
            return $0.id < $1.id
        }
    }
}
