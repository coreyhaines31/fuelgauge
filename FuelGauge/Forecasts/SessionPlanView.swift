import FuelGaugeCore
import SwiftUI

struct SessionPlanView: View {
    let forecasts: [Forecast]
    let now: Date
    @State var minutes = 120

    private var plan: SessionPlan? { SessionPlan(forecasts: forecasts, minutes: minutes, now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Plan your next session").font(.headline)
                Spacer()
                if let provider = forecasts.first?.key.provider {
                    Text("All tracked \(provider.name) limits").font(.caption).foregroundStyle(.secondary)
                }
            }
            Picker("Continue working for", selection: $minutes) {
                ForEach([30, 60, 120, 240], id: \.self) {
                    Text(ForecastText.duration(Double($0) * 60)).tag($0)
                }
            }.pickerStyle(.segmented)
            if let plan {
                Label(summary(plan), systemImage: plan.firstExhaustion == nil ? "clock" : "exclamationmark.triangle")
                    .font(.callout.weight(.medium))
                ForEach(plan.limits) { limit in
                    Divider()
                    SessionPlanLimitView(limit: limit, now: now)
                }
            }
            Text("Assumes this session's pace continues. Projections stop at quota resets; "
                 + "saved resets are not assumed to be redeemed.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func summary(_ plan: SessionPlan) -> String {
        if let first = plan.firstExhaustion {
            let name = first.forecast.windowName
            if first.outcome == .exhausted { return "\(name) limit is already out." }
            if let at = plan.exhaustionTime(first) {
                return "\(name) limit runs out first, around \(ForecastText.time(at, now: now))."
            }
        }
        if plan.hasUnknownUsage { return "Some limits can't be projected for the full session." }
        return "Tracked limits stay below 100% at this pace."
    }
}
