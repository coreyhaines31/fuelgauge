import FuelGaugeCore
import SwiftUI

struct ForecastLearningView: View {
    let forecast: Forecast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your usual hours").font(.headline)
                Spacer()
                Text(status).font(.callout).foregroundStyle(.secondary)
            }
            Text(explanation).font(.callout).foregroundStyle(.secondary)
            if forecast.scheduleStatus != .shortWindow, let evidence = forecast.scheduleEvidence {
                if let profile = forecast.scheduleProfile, profile.hours.contains(where: { $0.ratePerHour != nil }) {
                    ScheduleProfileView(profile: profile, isApplied: forecast.basis == .schedule)
                    if evidence.isReady {
                        DisclosureGroup("Learning requirements") { requirements(evidence).padding(.top, 8) }
                            .font(.callout)
                    } else {
                        requirements(evidence)
                    }
                } else {
                    requirements(evidence)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func requirements(_ evidence: ScheduleEvidence) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 12) {
            GridRow {
                progress("History", value: evidence.ageDays,
                         required: ScheduleEvidence.requiredAgeDays, unit: "days")
                progress("Observed in the last 14 days", value: evidence.observedHours,
                         required: ScheduleEvidence.requiredObservedHours, unit: "hours")
            }
            GridRow {
                progress("Dates with observed intervals", value: Double(evidence.observedDays),
                         required: ScheduleEvidence.requiredObservedDays, unit: "days")
                progress("Supported hours of the day", value: Double(evidence.supportedHours),
                         required: ScheduleEvidence.requiredSupportedHours, unit: "of 24 hours")
            }
        }
    }

    private var status: String {
        switch forecast.scheduleStatus {
        case .ready: "Schedule ready"
        case .shortWindow: "Recent pace fits this limit"
        case .collecting: "Learning automatically"
        case .correction, .missingHours, .distantReset: "Using recent pace when available"
        }
    }

    private var explanation: String {
        switch forecast.scheduleStatus {
        case .ready:
            "Enough history to learn local hours and weekday/weekend patterns. "
                + "Forecasts still need a reliable current reading."
        case .shortWindow:
            "Limits shorter than a day use recent pace, so they can respond quickly to the current session."
        case .collecting:
            "Nights and weekends are learned from readings. Missing hours are never assumed quiet. "
                + "All four requirements below must be met."
        case .correction:
            "Usage was corrected within this window. Recent pace uses the new baseline until the next reset."
        case .missingHours:
            "Some upcoming hours have no supported schedule or recent pace yet. More readings are needed."
        case .distantReset:
            "The reset is more than 35 days away, beyond the learned schedule's forecasting range."
        }
    }

    private func progress(_ title: String, value: Double, required: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: value >= Double(required) ? "checkmark.circle" : "circle.dotted")
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(.caption).foregroundStyle(.secondary)
            let label = Int(value) == 1 && unit.hasSuffix("s") ? String(unit.dropLast()) : unit
            Text("\(Int(value)) \(label) · need \(required)").font(.callout.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
