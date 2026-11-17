import Foundation
import FuelGaugeCore

enum ScheduleProfileText {
    static func time(_ hour: Int) -> String {
        let normalized = hour % 24
        return "\(normalized % 12 == 0 ? 12 : normalized % 12)\(normalized < 12 ? "a" : "p")"
    }

    static func title(_ hour: ScheduleProfile.Hour) -> String {
        let day = hour.day == .weekday ? "Weekdays" : "Weekends"
        let when = "\(day), \(time(hour.hour))–\(time(hour.hour + 1))"
        guard let rate = hour.ratePerHour else { return "\(when) · Not enough observations" }
        if rate == 0 { return "\(when) · \(hour.source == .pooled ? "Estimated quiet" : "Observed quiet")" }
        let value = rate < 0.1 ? "<0.1" : rate.formatted(.number.precision(.fractionLength(1)))
        return "\(when) · \(value) percentage points/hour"
    }

    static func detail(_ hour: ScheduleProfile.Hour) -> String {
        let hours = hour.observedHours.formatted(.number.precision(.fractionLength(1)))
        let dates = "\(hour.observedDates) \(hour.observedDates == 1 ? "date" : "dates")"
        let evidence = "\(hours) observed hours across \(dates)."
        switch hour.source {
        case .observed: return "\(evidence) Older readings receive less weight."
        case .pooled: return "\(evidence) Borrows this hour's average across all days; this day group needs more data."
        case .unknown:
            return "\(evidence) Needs \(ScheduleProfile.requiredDates) dates and "
                + "\(Int(ScheduleProfile.requiredHours)) observed hours. Missing data is not quiet time."
        }
    }
}
