import Charts
import FuelGaugeCore
import SwiftUI

/// The window so far as a line, and where it's headed as a dashed line to the reset or the run-out point.
struct ForecastChart: View {
    let forecast: Forecast
    let now: Date
    let tint: Color

    var body: some View {
        Chart {
            ForEach(points, id: \.date) { point in
                LineMark(x: .value("Time", point.date), y: .value("Used", point.used), series: .value("Line", "used"))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(tint == .secondary ? Color.gray : tint)
            }
            if let projection {
                ForEach(projection, id: \.date) { point in
                    LineMark(
                        x: .value("Time", point.date), y: .value("Used", point.used),
                        series: .value("Line", "projection")
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .foregroundStyle(tint == .secondary ? Color.gray : tint)
                }
            }
            RuleMark(y: .value("Limit", 100))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.secondary)
            RuleMark(x: .value("Reset", forecast.resetsAt))
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                .foregroundStyle(.secondary)
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: start...forecast.resetsAt)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%").font(.system(size: 9)) }
            }
        }
        .chartXAxis(.hidden)
        .accessibilityLabel("\(forecast.windowName) usage over time")
    }

    private struct Point {
        let date: Date
        let used: Double
    }

    /// From the window's start, or the first reading if that's later.
    private var start: Date {
        let first = forecast.history.first?.at ?? now
        guard let minutes = forecast.windowMinutes else { return first }
        return max(forecast.resetsAt.addingTimeInterval(-Double(minutes) * 60), first)
    }

    private var points: [Point] {
        let history = forecast.history.filter { $0.at >= start }.map { Point(date: $0.at, used: $0.usedPercent) }
        return history + [Point(date: now, used: forecast.usedPercent)]
    }

    private var projection: [Point]? {
        let from = Point(date: now, used: forecast.usedPercent)
        switch forecast.verdict {
        case .runsOut(let at, _, _):
            return [from, Point(date: at, used: 100)]
        case .makesIt(let projected):
            return [from, Point(date: forecast.resetsAt, used: projected)]
        default:
            return nil
        }
    }
}
