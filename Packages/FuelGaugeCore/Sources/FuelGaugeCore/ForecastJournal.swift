import Foundation

public struct ForecastJournal: Codable, Sendable, Equatable {
    public private(set) var schemaVersion = 1
    public private(set) var records: [ForecastRecord] = []
    public static let retentionDays = 60
    public static let maximumRecords = 10_000

    public init() {}

    public mutating func update(forecasts: [Forecast], readings: [Reading], now: Date, appVersion: String) {
        let grouped = Dictionary(grouping: readings.filter { $0.at <= now }, by: \.key)
        let timelines = grouped.mapValues { ReadingTimeline($0, now: now) }
        for index in records.indices {
            for targetIndex in records[index].targets.indices {
                let record = records[index]
                let target = record.targets[targetIndex]
                guard target.outcome == .pending, target.at <= now else { continue }
                records[index].targets[targetIndex] = Self.resolve(target, source: record.source,
                    issuedAt: record.issuedAt, timeline: timelines[record.source.key], now: now)
            }
        }
        let hour = floor(now.timeIntervalSince1970 / 3600)
        let recorded = Set(records.filter { floor($0.issuedAt.timeIntervalSince1970 / 3600) == hour }
            .map { $0.source.key })
        for forecast in forecasts where !recorded.contains(forecast.key) {
            guard forecast.verdict != .reset, forecast.verdict != .stale, forecast.verdict != .limitReached,
                  let timeline = timelines[forecast.key], !timeline.hasConflict,
                  let source = timeline.segments.last?.last else { continue }
            let recent = ForecastEngine.forecast(for: grouped[forecast.key] ?? [], now: now, method: .recent)
            records.append(ForecastRecord(forecast: forecast, recent: recent, source: source,
                                          now: now, appVersion: appVersion))
        }
        let cutoff = now.addingTimeInterval(-Double(Self.retentionDays) * 86400)
        records.removeAll { $0.issuedAt < cutoff }
        if records.count > Self.maximumRecords { records.removeFirst(records.count - Self.maximumRecords) }
    }

    private static func resolve(_ target: ForecastRecord.Target, source: Reading, issuedAt: Date,
                                timeline: ReadingTimeline?, now: Date) -> ForecastRecord.Target {
        var result = target
        // A historical reading imported after this deadline is not a live outcome.
        if now > target.at.addingTimeInterval(900) {
            result.outcome = .missing
        } else if let timeline, let segment = timeline.segments.last, let first = segment.first {
            if first.at > issuedAt || !ReadingTimeline.sameWindow(source, first) {
                result.outcome = .changed
            } else if !timeline.hasConflict,
                      let actual = segment.first(where: { $0.at >= target.at }), actual.at < source.resetsAt,
                      actual.usedPercent >= source.usedPercent {
                result.outcome = .observed
                result.actual = actual
                result.receivedAt = now
            }
        }
        if result.outcome == .missing, let timeline {
            if timeline.hasConflict {
                result.outcome = .unreliable
            } else if let first = timeline.segments.last?.first,
                      first.at > issuedAt || !ReadingTimeline.sameWindow(source, first) {
                result.outcome = .changed
            }
        }
        return result
    }
}
