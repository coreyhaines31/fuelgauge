import Charts
import FuelGaugeCore
import PanelKit
import SwiftUI

/// The recent stretch of a window as a graphite line, and where it's headed as a dashed line in the warning
/// colour to the run-out point or the reset. Weekly windows show the last day rather than a sliver of the whole
/// week.
struct ForecastChart: View {
    let forecast: Forecast
    let now: Date
    /// The warning colour for the projection and the run-out label.
    let tint: Color
    @Environment(\.panelTheme) private var theme

    var body: some View {
        Chart {
            ForEach(points, id: \.date) { point in
                LineMark(x: .value("Time", point.date), y: .value("Used", point.used), series: .value("Line", "used"))
                    .interpolationMethod(.stepEnd)
                    .lineStyle(StrokeStyle(lineWidth: 1.6))
                    .foregroundStyle(theme.fill)
            }
            ForEach(projection, id: \.date) { point in
                LineMark(x: .value("Time", point.date), y: .value("Used", point.used),
                         series: .value("Line", "projection"))
                    .lineStyle(StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
                    .foregroundStyle(tint)
            }
            if case .runsOut = forecast.verdict, endPoint <= range.upperBound {
                PointMark(x: .value("Time", endPoint), y: .value("Used", 100))
                    .symbolSize(28)
                    .foregroundStyle(tint)
            }
            RuleMark(y: .value("Limit", 100))
                .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [2, 3]))
                .foregroundStyle(theme.sub)
            RuleMark(x: .value("Now", now))
                .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [2, 2]))
                .foregroundStyle(theme.sub)
            if range.contains(forecast.resetsAt) {
                RuleMark(x: .value("Reset", forecast.resetsAt))
                    .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [2, 2]))
                    .foregroundStyle(theme.sub)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: range)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine().foregroundStyle(theme.line)
                AxisValueLabel {
                    Text("\(value.as(Int.self) ?? 0)%").font(PanelFont.body(8.5)).foregroundStyle(theme.sub)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                let date = value.as(Date.self) ?? now
                // A label near the right edge hangs to the left, so it isn't cut off.
                AxisValueLabel(anchor: nearRightEdge(date) ? .topTrailing : .top) {
                    Text(label(for: date))
                        .font(PanelFont.body(8.5, isRunOut(date) ? .semibold : .regular))
                        .foregroundStyle(isRunOut(date) ? tint : theme.sub)
                }
            }
        }
        .accessibilityLabel("\(forecast.windowName) usage over time")
    }

    private struct Point {
        let date: Date
        let used: Double
    }

    private var range: ClosedRange<Date> {
        ForecastEngine.chartRange(forecast, now: now)
    }

    private var endPoint: Date {
        if case .runsOut(let at, _, _) = forecast.verdict { return min(at, range.upperBound) }
        return range.upperBound
    }

    /// "Now" and the end, unless they'd sit on top of each other; then just the end.
    private var axisDates: [Date] {
        let width = range.upperBound.timeIntervalSince(range.lowerBound)
        return endPoint.timeIntervalSince(now) < width * 0.25 ? [endPoint] : [now, endPoint]
    }

    private func nearRightEdge(_ date: Date) -> Bool {
        let width = range.upperBound.timeIntervalSince(range.lowerBound)
        return range.upperBound.timeIntervalSince(date) < width * 0.15
    }

    private func isRunOut(_ date: Date) -> Bool {
        guard case .runsOut = forecast.verdict else { return false }
        return date == endPoint && abs(date.timeIntervalSince(now)) >= 60
    }

    private func label(for date: Date) -> String {
        if abs(date.timeIntervalSince(now)) < 60 { return "Now" }
        if date == endPoint, case .runsOut = forecast.verdict { return "Out ~\(ForecastText.time(date, now: now))" }
        if abs(date.timeIntervalSince(forecast.resetsAt)) < 60 { return "Reset \(ForecastText.time(date, now: now))" }
        return ForecastText.time(date, now: now)
    }

    /// The readings inside the chart, starting from the value in effect at its left edge.
    private var points: [Point] {
        let start = range.lowerBound
        let before = forecast.history.last { $0.at <= start }
        var points = before.map { [Point(date: start, used: $0.usedPercent)] } ?? []
        points += forecast.history.filter { $0.at > start }.map { Point(date: $0.at, used: $0.usedPercent) }
        return points + [Point(date: now, used: forecast.usedPercent)]
    }

    private var projection: [Point] {
        if !forecast.projection.isEmpty {
            return forecast.projection.map { Point(date: $0.at, used: $0.usedPercent) }
        }
        let from = Point(date: now, used: forecast.usedPercent)
        switch forecast.verdict {
        case .runsOut(let at, _, _):
            return [from, Point(date: at, used: 100)]
        case .makesIt(let projected):
            return [from, Point(date: forecast.resetsAt, used: projected)]
        default:
            return []
        }
    }
}
