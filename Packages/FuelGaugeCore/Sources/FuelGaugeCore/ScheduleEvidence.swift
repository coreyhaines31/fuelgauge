import Foundation

public struct ScheduleEvidence: Sendable, Equatable {
    public static let requiredAgeDays = 14
    public static let requiredObservedHours = 168
    public static let requiredObservedDays = 7
    public static let requiredSupportedHours = 12

    public let ageDays: Double
    public let observedHours: Double
    public let observedDays: Int
    public let supportedHours: Int

    public var isReady: Bool {
        ageDays >= Double(Self.requiredAgeDays) && observedHours >= Double(Self.requiredObservedHours)
            && observedDays >= Self.requiredObservedDays && supportedHours >= Self.requiredSupportedHours
    }
}
