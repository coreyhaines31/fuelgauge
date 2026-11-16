import FuelGaugeCore
import PanelKit
import SwiftUI

/// One tool's limits as a panel section: a row per window, shortest window first, then usage and resets.
struct ToolCard: View {
    let provider: Provider
    let forecasts: [Forecast]
    let now: Date
    /// The one window in the whole panel that gets a chart: the most urgent one that's running short.
    let chartKey: LimitKey?
    var model: UsageModel?
    var openSettings: () -> Void = {}
    var openUsage: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(provider.name)
            ForEach(forecasts, id: \.key) { forecast in
                WindowRow(forecast: forecast, now: now, showsChart: forecast.key == chartKey)
            }
            if let model, provider == .claude || provider == .codex {
                usageRow(model)
            }
            if let model {
                ResetCreditRow(provider: provider, model: model, now: now, openSettings: openSettings)
            }
            if model != nil, provider == .claude || provider == .codex {
                LinkBar {
                    Button("Details ›", action: openUsage)
                    if provider == .claude {
                        Link("Check resets in Claude Usage ↗",
                             destination: URL(string: "https://claude.ai/settings/usage")!)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    private func usageRow(_ model: UsageModel) -> some View {
        let summary = model.todayUsage(for: provider, now: now)
        return Group {
            if summary.events > 0 {
                InfoRow("Today · This Mac", lines: ["Estimated API cost · USD"],
                        value: "\(summary.tokens.total.formatted(.number.notation(.compactName))) tokens",
                        secondary: summary.costLabel)
            } else {
                InfoRow("Today · This Mac",
                        lines: [model.scanningUsage ? "Reading usage history…" : "No usage recorded today"])
            }
        }
    }
}

/// One window. A plain row when it's fine or still learning; an open disclosure with the full story when it's
/// running short.
struct WindowRow: View {
    let forecast: Forecast
    let now: Date
    let showsChart: Bool
    @Environment(\.panelTheme) private var theme

    var body: some View {
        if forecast.isShort {
            Disclosure(forecast.windowName, subtitle: ForecastText.headline(forecast, now: now),
                       value: ForecastText.percent(forecast.usedPercent), initiallyExpanded: true) {
                expanded
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                InfoRow(forecast.windowName,
                        lines: [compactLine] + (ForecastText.context(forecast, now: now).map { [$0] } ?? []),
                        value: ForecastText.percent(forecast.usedPercent))
                ProjectedTape(used: forecast.usedPercent, projected: projected, status: status)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
        }
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProjectedTape(used: forecast.usedPercent, projected: projected, status: status)
                .padding(.bottom, 4)
            Group {
                Text(ForecastText.usage(forecast, now: now))
                if let pace = ForecastText.pace(forecast, now: now) {
                    Text(pace)
                }
                if let range = ForecastText.range(forecast, now: now) {
                    Text(range)
                }
            }
            .font(PanelFont.body(11.5))
            .foregroundStyle(theme.sub)
            .fixedSize(horizontal: false, vertical: true)
            if showsChart, forecast.history.count >= 2 {
                ForecastChart(forecast: forecast, now: now, tint: theme.color(for: status ?? .off))
                    .frame(height: 76)
                    .padding(.top, 6)
            }
        }
        .padding(.leading, 46)
        .padding(.trailing, 14)
        .padding(.bottom, 10)
    }

    /// "Makes it, about 14% by then · resets 2p", or "Learning your pace, forecast in about 2h · resets 2p".
    private var compactLine: String {
        var resets = "resets \(ForecastText.time(forecast.resetsAt, now: now))"
        if let asOf = ForecastText.asOf(forecast, now: now) { resets += " · \(asOf)" }
        switch forecast.verdict {
        case .learning:
            return "Learning your pace, \(ForecastText.learning(forecast, now: now).lowercased()) · \(resets)"
        case .reset:
            return ForecastText.headline(forecast, now: now)
        default:
            return "\(ForecastText.headline(forecast, now: now)) · \(resets)"
        }
    }

    /// Where the tape's faint extension ends: the projected percent at reset.
    private var projected: Double? {
        switch forecast.verdict {
        case .makesIt(let projected): projected
        case .runsOut: 100
        default: nil
        }
    }

    /// Colour only when the window runs short; graphite otherwise.
    private var status: PanelStatus? {
        switch forecast.verdict {
        case .limitReached: .stop
        case .runsOut: .caution
        case .makesIt, .learning, .stale, .reset: nil
        }
    }
}
