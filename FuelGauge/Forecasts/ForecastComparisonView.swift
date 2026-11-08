import FuelGaugeCore
import SwiftUI

struct ForecastComparisonView: View {
    let point: ForecastComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(point.at.formatted(date: .abbreviated, time: .shortened)).font(.callout.weight(.medium))
            HStack(alignment: .top, spacing: 18) {
                metric("Predicted", value: percent(point.predicted))
                metric("Actual", value: percent(point.actual?.usedPercent))
                metric("Forecast error", value: error)
            }
            Text(explanation).font(.callout)
            Text("Made \(point.record.issuedAt.formatted(date: .abbreviated, time: .shortened)) · "
                 + "\(point.target.hours)h ahead · \(method) · v\(point.record.appVersion)")
                .font(.caption).foregroundStyle(.secondary)
            DisclosureGroup("Saved forecast details") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target: \(point.target.at.formatted(date: .abbreviated, time: .shortened))")
                    Text("Window reset: "
                         + point.record.source.resetsAt.formatted(date: .abbreviated, time: .shortened))
                    Text("Recent-pace baseline: \(percent(point.recent))")
                    if let received = point.target.receivedAt, point.actual != nil {
                        Text("Reading received: \(received.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
                .font(.caption).foregroundStyle(.secondary).padding(.top, 5)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.medium)).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func percent(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(1))) + "%" } ?? "—"
    }

    private var error: String {
        guard let error = point.error else { return "Unscored" }
        return abs(error).formatted(.number.precision(.fractionLength(1))) + " pp"
    }

    private var method: String {
        point.record.basis == "schedule" ? "Learned hours" : "Recent pace"
    }

    private var explanation: String {
        switch point.target.outcome {
        case .observed:
            guard let error = point.error else { return "A reading arrived, but no comparable estimate was saved." }
            if abs(error) < 0.05 { return "The prediction matched observed usage to one decimal place." }
            return "Predicted \(error > 0 ? "more" : "less") usage than observed. "
                + "Both values use the reading's actual time."
        case .pending:
            return "Waiting for a reading at the target or within 15 minutes afterward."
        case .missing:
            return "No timely reading arrived. This gap stays unscored; it does not mean zero usage."
        case .changed:
            return "The quota window or usage baseline changed. This comparison is excluded."
        case .unreliable:
            return "Conflicting readings prevented a reliable comparison. This outcome is unscored."
        case .beyondReset:
            return "The target falls at or after the saved window's reset. No estimate was made."
        }
    }
}
