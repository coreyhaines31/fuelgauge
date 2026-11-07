import FuelGaugeCore
import SwiftUI

struct ForecastAccuracyView: View {
    let results: [ForecastAccuracy]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Measured forecast error").font(.headline)
                Spacer()
                Text("Last 30 days").font(.callout).foregroundStyle(.secondary)
            }
            Text("Average error in percentage points; lower is better. Both methods use the same observed outcomes.")
                .font(.callout).foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                GridRow {
                    Text("Ahead")
                    Text("Fuel Gauge")
                    Text("Recent pace")
                    Text("Evidence")
                }
                .font(.caption).foregroundStyle(.secondary)
                ForEach(results, id: \.hours) { result in
                    GridRow {
                        Text("\(result.hours) hour\(result.hours == 1 ? "" : "s")")
                        Text(error(result.adaptiveMAE))
                        Text(error(result.recentMAE))
                        Text("\(result.paired) pairs · \(result.pairedDays) days")
                    }
                    .font(.callout.monospacedDigit())
                }
            }
            if results.contains(where: { !$0.hasEnoughEvidence }) {
                Text("Collecting outcomes · Each row needs \(ForecastAccuracy.requiredPairs) paired observations "
                     + "across \(ForecastAccuracy.requiredDays) days before showing an error score.")
                    .font(.callout)
            }
            DisclosureGroup("Observation coverage") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(results, id: \.hours) { result in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(result.hours)h: \(result.observed) observed · \(result.pending) pending")
                                .fontWeight(.medium)
                            Text("\(result.missing) missed · \(result.changed) reset/correction · "
                                 + "\(result.unreliable) conflicting · \(result.beyondReset) beyond reset")
                            Text("Forecasts available: Fuel Gauge \(result.adaptiveAvailable), "
                                 + "recent pace \(result.recentAvailable). "
                                 + "\(result.scheduledPairs) pairs used learned hours.")
                        }
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
            }
            .font(.callout)
            Text("Readings must arrive within 15 minutes of the target. Missed readings stay unscored. "
                 + "Hourly comparisons overlap; these scores are not confidence percentages.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func error(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(1))) + " pp" } ?? "—"
    }
}
