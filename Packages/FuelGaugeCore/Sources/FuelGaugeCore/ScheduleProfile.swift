import Foundation

public struct ScheduleProfile: Sendable, Equatable {
    public static let requiredDates = 2
    public static let requiredHours = 2.0

    public enum Day: String, CaseIterable, Sendable { case weekday, weekend }
    public enum Source: Sendable { case observed, pooled, unknown }

    public struct Hour: Sendable, Equatable, Identifiable {
        public let day: Day
        public let hour: Int
        public let ratePerHour: Double?
        public let observedHours: Double
        public let observedDates: Int
        public let source: Source

        public var id: String { "\(day.rawValue)-\(hour)" }
    }

    public struct Activity: Sendable, Equatable {
        public static let requiredHours = 12.0
        public let observedHours: Double
        public let actualUsage: Double
        public let expectedUsage: Double

        public var ratio: Double? {
            observedHours >= Self.requiredHours && expectedUsage >= 1 ? actualUsage / expectedUsage : nil
        }

        public var multiplier: Double? { ratio.map { min(2, max(0.5, $0)) } }
    }

    public let hours: [Hour]
    public let timeZoneIdentifier: String
    public let recentActivity: Activity?
}
