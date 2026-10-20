import FuelGaugeCore
import SwiftUI

/// One tool's limits in a card: a row per window, shortest window first.
struct ToolCard: View {
    let provider: Provider
    let forecasts: [Forecast]
    let now: Date
    /// The one window in the whole panel that gets a chart: the most urgent one that's running short.
    let chartKey: LimitKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(provider.name)
                .font(.system(size: 13, weight: .semibold))
            ForEach(Array(forecasts.enumerated()), id: \.element.key) { index, forecast in
                if index > 0 { Divider() }
                WindowRow(forecast: forecast, now: now, showsChart: forecast.key == chartKey)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

/// One window. Compact when it's fine or still learning; the full story when it's running short.
struct WindowRow: View {
    let forecast: Forecast
    let now: Date
    let showsChart: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(forecast.windowName)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(ForecastText.percent(forecast.usedPercent))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            UsageBar(used: forecast.usedPercent, projected: projected, tint: tint)
            if forecast.isShort {
                expanded
            } else {
                Text(compactLine)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ForecastText.headline(forecast, now: now))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(ForecastText.usage(forecast, now: now))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            if let pace = ForecastText.pace(forecast, now: now) {
                Text(pace)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let range = ForecastText.range(forecast, now: now) {
                Text(range)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            if showsChart, forecast.history.count >= 2 {
                ForecastChart(forecast: forecast, now: now, tint: tint)
                    .frame(height: 76)
                    .padding(.top, 4)
            }
        }
    }

    /// "Makes it, about 14% by then · resets 2p", or "Learning your pace, forecast in about 2h · resets 2p".
    private var compactLine: String {
        let resets = "resets \(ForecastText.time(forecast.resetsAt, now: now))"
        switch forecast.verdict {
        case .learning:
            return "Learning your pace, \(ForecastText.learning(forecast, now: now).lowercased()) · \(resets)"
        case .reset:
            return ForecastText.headline(forecast, now: now)
        default:
            return "\(ForecastText.headline(forecast, now: now)) · \(resets)"
        }
    }

    /// Where the bar's faint extension ends: the projected percent at reset.
    private var projected: Double? {
        switch forecast.verdict {
        case .makesIt(let projected): projected
        case .runsOut: 100
        default: nil
        }
    }

    private var tint: Color {
        WindowRow.tint(for: forecast.verdict)
    }

    static func tint(for verdict: Forecast.Verdict) -> Color {
        switch verdict {
        case .limitReached: .red
        case .runsOut: .orange
        case .makesIt: .green
        case .learning, .reset: .secondary
        }
    }
}

/// A bar of the percent used, with a faint extension to where it's headed by reset.
struct UsageBar: View {
    let used: Double
    let projected: Double?
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                if let projected, projected > used {
                    Capsule().fill(tint.opacity(0.25))
                        .frame(width: width * min(projected, 100) / 100)
                }
                Capsule().fill(tint == .secondary ? Color.gray : tint)
                    .frame(width: max(5, width * min(used, 100) / 100))
            }
        }
        .frame(height: 5)
    }
}
