import FuelGaugeCore
import SwiftUI

/// One limit: the verdict first, then the numbers behind it, then the chart.
struct LimitCard: View {
    let forecast: Forecast
    let now: Date
    var showsChart = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(forecast.key.provider.name) · \(forecast.windowName)")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(ForecastText.percent(forecast.usedPercent))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            UsageBar(used: forecast.usedPercent, projected: projected, tint: tint)
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
                    .frame(height: 64)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
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
        Self.tint(for: forecast.verdict)
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
                    .frame(width: max(6, width * min(used, 100) / 100))
            }
        }
        .frame(height: 6)
    }
}
