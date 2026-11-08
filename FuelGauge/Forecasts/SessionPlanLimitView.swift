import FuelGaugeCore
import SwiftUI

struct SessionPlanLimitView: View {
    let limit: SessionPlan.Limit
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(limit.forecast.windowName).fontWeight(.medium)
                Spacer()
                Text("\(ForecastText.percent(limit.forecast.usedPercent)) reported")
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right").foregroundStyle(.secondary).accessibilityHidden(true)
                Text(projectedLabel).fontWeight(.medium)
            }
            .font(.callout).monospacedDigit()
            if case .projected(let projection) = limit.outcome {
                ProgressView(value: projection.usedPercent, total: 100)
                    .tint(projection.runsOutAt == nil ? Color.accentColor : .orange)
                    .accessibilityLabel("Projected usage of \(limit.forecast.windowName.lowercased()) limit")
                Text(projectionDetail(projection)).font(.callout)
                Text("Pace: \(projection.ratePerHour.formatted(.number.precision(.fractionLength(1)))) "
                     + "percentage points/hour · Reading \(ForecastText.time(limit.forecast.lastReadingAt, now: now))")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text(unavailableDetail).font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var projectedLabel: String {
        switch limit.outcome {
        case .projected(let projection): "~\(projection.usedPercent.formatted(.number.precision(.fractionLength(1))))%"
        case .exhausted: "Already out"
        default: "Unknown"
        }
    }

    private func projectionDetail(_ projection: SessionPlan.Projection) -> String {
        var detail: String
        if let out = projection.runsOutAt {
            detail = "Runs out around \(ForecastText.time(out, now: now)) "
                + "(in \(ForecastText.duration(out.timeIntervalSince(now))))."
        } else {
            detail = "About \(ForecastText.percent(100 - projection.usedPercent)) left "
                + "at \(ForecastText.time(projection.until, now: now))."
        }
        if projection.stopsAtReset {
            detail += " Projection stops at the \(ForecastText.time(projection.until, now: now)) reset; "
                + "usage in the next window is unknown."
        }
        return detail
    }

    private var unavailableDetail: String {
        switch limit.outcome {
        case .needsFreshReading:
            "Use the tool to refresh its limits. A reliable reading from the last 15 minutes is needed."
        case .needsActivity:
            "Keep working for at least 10 minutes with fresh readings to estimate this session's pace."
        case .inactive:
            "No recent usage increase. Start working to estimate an active pace."
        case .reset:
            "This window reset. Use the tool for a reading from the new window."
        case .exhausted:
            "Out until \(ForecastText.time(limit.forecast.resetsAt, now: now)). Usage after reset is unknown."
        case .projected:
            ""
        }
    }
}
