import Charts
import FuelGaugeCore
import SwiftUI

struct ForecastTimelineChart: View {
    let points: [ForecastComparison]
    let selected: ForecastComparison?
    let now: Date
    @Binding var selectionDate: Date?

    var body: some View {
        Chart {
            ForEach(points) { point in
                if let predicted = point.predicted, let actual = point.actual {
                    RuleMark(x: .value("Time", point.at), yStart: .value("Predicted", predicted),
                             yEnd: .value("Actual", actual.usedPercent))
                        .foregroundStyle(Color.secondary.opacity(0.4))
                }
                if let predicted = point.predicted {
                    PointMark(x: .value("Time", point.at), y: .value("Predicted", predicted))
                        .symbol(.diamond).symbolSize(42).foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Saved forecast").accessibilityValue("\(ForecastText.percent(predicted))")
                }
                if let actual = point.actual {
                    PointMark(x: .value("Time", point.at), y: .value("Actual", actual.usedPercent))
                        .symbol(.circle).symbolSize(18).foregroundStyle(Color.primary)
                        .accessibilityLabel("Observed usage")
                        .accessibilityValue("\(ForecastText.percent(actual.usedPercent))")
                }
            }
            if range.contains(now) {
                RuleMark(x: .value("Now", now))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4])).foregroundStyle(Color.secondary.opacity(0.5))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Now").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            if let selected {
                RuleMark(x: .value("Selected", selected.at))
                    .foregroundStyle(Color.primary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartXScale(domain: range)
        .chartYScale(domain: 0...100)
        .chartXSelection(value: $selectionDate)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%").font(.caption2) }
            }
        }
        .frame(height: 190)
        .padding(.top, 8)
        .accessibilityLabel("Saved forecasts and observed usage. Select a time or use the forecast navigation buttons.")
    }

    private var range: ClosedRange<Date> {
        let first = points.map(\.at).min() ?? now
        let last = points.map(\.at).max() ?? now
        let padding = max(1800, last.timeIntervalSince(first) * 0.03)
        return first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
    }
}
