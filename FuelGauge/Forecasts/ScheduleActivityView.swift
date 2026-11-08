import FuelGaugeCore
import SwiftUI

struct ScheduleActivityView: View {
    let activity: ScheduleProfile.Activity?
    let isApplied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let activity, let ratio = activity.ratio, let multiplier = activity.multiplier {
                Text("Recent workload · \(factor(ratio))× usual").font(.callout.weight(.medium))
                let hours = activity.observedHours.formatted(.number.precision(.fractionLength(0)))
                Text("Compared over \(hours) observed hours during the last 3 days.")
                    .font(.caption).foregroundStyle(.secondary)
                if !isApplied {
                    Text("Historical comparison. See Current forecast for the method in use.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if abs(multiplier - 1) < 0.05 {
                    Text("Recent activity is close to your usual pattern.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if abs(ratio - multiplier) > 0.001 {
                    Text("Forecast adjustment: \(factor(multiplier))×, easing back toward your usual pattern.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("This adjustment fades toward your usual pattern over the next few days.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Recent workload · Still learning").font(.callout.weight(.medium))
                Text("Needs a learned schedule, at least 12 comparable hours in the last 3 days, "
                     + "and some usual activity to compare with.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }

    private func factor(_ value: Double) -> String {
        value > 0 && value < 0.1 ? "<0.1" : value.formatted(.number.precision(.fractionLength(1)))
    }
}
