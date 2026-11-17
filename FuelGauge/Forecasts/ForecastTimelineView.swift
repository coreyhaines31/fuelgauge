import FuelGaugeCore
import SwiftUI

struct ForecastTimelineView: View {
    let history: [ForecastComparison]
    let now: Date
    @State var hours = 1
    @State var days = 7
    @State var selectedID: String?
    @State private var selectionDate: Date?

    private var points: [ForecastComparison] {
        history.filter {
            $0.target.hours == hours && $0.record.issuedAt >= now.addingTimeInterval(-Double(days) * 86400)
        }
    }

    private var selected: ForecastComparison? {
        points.first { $0.id == selectedID } ?? points.last { $0.actual != nil } ?? points.last
    }

    private var selectedIndex: Int? { points.firstIndex { $0.id == selected?.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predicted vs. actual").font(.headline)
            controls
            if points.isEmpty {
                Text("No saved forecasts in this period yet. Recording runs automatically while Fuel Gauge is open.")
                    .font(.callout).foregroundStyle(.secondary).padding(.vertical, 12)
            } else {
                legend
                ForecastTimelineChart(points: points, selected: selected, now: now, selectionDate: $selectionDate)
                navigation
                if let selected { ForecastComparisonView(point: selected) }
                Text(coverage).font(.caption).foregroundStyle(.secondary)
                Text("Each pair is one saved forecast and its timely reading. Gaps stay unscored. "
                     + "Select a time or browse with the arrows. Times are local.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: selectionDate) { _, date in
            guard let date else { return }
            selectedID = points.min { abs($0.at.timeIntervalSince(date)) < abs($1.at.timeIntervalSince(date)) }?.id
        }
        .onChange(of: hours) { _, _ in clearSelection() }
        .onChange(of: days) { _, _ in clearSelection() }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Picker("Forecast horizon", selection: $hours) {
                ForEach([1, 6, 24], id: \.self) { Text("\($0)h ahead").tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 240)
            Spacer(minLength: 0)
            Picker("Issued", selection: $days) {
                Text("Last 7 days").tag(7)
                Text("Last 30 days").tag(30)
            }.frame(width: 180)
        }
    }

    private var legend: some View {
        HStack(spacing: 18) {
            Label { Text("Saved prediction") } icon: {
                Image(systemName: "diamond.fill").foregroundStyle(Color.accentColor)
            }
            Label { Text("Actual reading") } icon: {
                Image(systemName: "circle.fill").foregroundStyle(Color.primary)
            }
        }.font(.caption).foregroundStyle(.secondary)
    }

    private var navigation: some View {
        HStack {
            Text("Forecast \((selectedIndex ?? 0) + 1) of \(points.count)")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            Spacer()
            Button { move(-1) } label: { Image(systemName: "chevron.left") }
                .disabled(selectedIndex == nil || selectedIndex == 0)
                .help("Previous forecast").accessibilityLabel("Previous forecast")
            Button { move(1) } label: { Image(systemName: "chevron.right") }
                .disabled(selectedIndex == nil || selectedIndex == points.count - 1)
                .help("Next forecast").accessibilityLabel("Next forecast")
        }
    }

    private var coverage: String {
        let counts = Dictionary(grouping: points, by: \.target.outcome).mapValues(\.count)
        let excluded = (counts[.changed] ?? 0) + (counts[.unreliable] ?? 0) + (counts[.beyondReset] ?? 0)
        return "\(counts[.observed] ?? 0) observed · \(counts[.pending] ?? 0) pending · "
            + "\(counts[.missing] ?? 0) missed · \(excluded) excluded"
    }

    private func move(_ offset: Int) {
        guard let selectedIndex, points.indices.contains(selectedIndex + offset) else { return }
        selectionDate = nil
        selectedID = points[selectedIndex + offset].id
    }

    private func clearSelection() {
        selectionDate = nil
        selectedID = nil
    }
}
