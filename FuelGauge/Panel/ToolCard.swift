import FuelGaugeCore
import PanelKit
import SwiftUI

/// One tool account's limits as a panel section: a row per window, shortest window first, then usage and
/// resets. Headed by the account's name when the tool has several.
struct ToolCard: View {
    let provider: Provider
    let forecasts: [Forecast]
    let now: Date
    /// The one window in the whole panel that gets a chart: the most urgent one that's running short.
    let chartKey: LimitKey?
    /// Nil for a tool without accounts (Grok Bot, Cursor).
    var account: Account?
    var model: UsageModel?
    var openSettings: () -> Void = {}
    var openUsage: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToolSectionHeader(provider: provider, accountName: accountName)
            ForEach(forecasts, id: \.key) { forecast in
                WindowRow(forecast: forecast, now: now, showsChart: forecast.key == chartKey,
                          note: modelNote(forecast))
            }
            if let model, let account, provider == .claude, let advice = model.resetAdvice(for: account, now: now) {
                Notice(advice.title, message: advice.text) {
                    Link("Open Claude Usage ↗", destination: URL(string: "https://claude.ai/settings/usage")!)
                }
            }
            if let model, let account {
                usageRow(model, account: account)
            }
            if let model, let account {
                ResetCreditRow(account: account, model: model, now: now, openSettings: openSettings)
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

    /// The account's name when its tool has several; nil keeps the header as it always was.
    private var accountName: String? {
        forecasts.first?.accountName
            ?? account.flatMap { model?.accounts.label(provider: provider, slug: $0.slug) }
    }

    /// "18% of your week so far · up to 50%" under a model's allowance, when Claude says.
    private func modelNote(_ forecast: Forecast) -> String? {
        guard let name = forecast.modelName, let account,
              let allowance = model?.claudeUsage(for: account)?.model(named: name),
              allowance.resetsAt > now, let used = allowance.usedPercentOfWeekly else { return nil }
        let cap = allowance.allowancePercentOfWeekly.map { " · up to \(ForecastText.percent($0))" } ?? ""
        return "\(ForecastText.percent(used)) of your week so far\(cap)"
    }

    private func usageRow(_ model: UsageModel, account: Account) -> some View {
        let summary = model.todayUsage(for: account, now: now)
        return Group {
            if summary.events > 0 {
                Row("Today · This Mac", subtitle: "Estimated API cost · USD",
                    value: "\(summary.tokens.total.formatted(.number.notation(.compactName))) tokens",
                    secondary: summary.costLabel)
            } else {
                Row("Today · This Mac",
                    subtitle: model.scanningUsage ? "Reading usage history…" : "No usage recorded today")
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
    /// An extra line, like a model allowance's share of the week.
    var note: String?
    @Environment(\.panelTheme) private var theme

    var body: some View {
        if forecast.isShort {
            Disclosure(forecast.windowName, subtitle: ForecastText.headline(forecast, now: now),
                       value: ForecastText.percent(forecast.usedPercent), initiallyExpanded: true) {
                expanded
            }
            .subtitleTint(status)
        } else {
            Row(forecast.windowName,
                subtitle: ([compactLine] + [ForecastText.context(forecast, now: now), note].compactMap { $0 })
                    .joined(separator: "\n"),
                value: ForecastText.percent(forecast.usedPercent),
                tape: RowTape(forecast.usedPercent / 100, projection: projected.map { $0 / 100 }, status: status))
            .subtitleLineLimit(nil)
        }
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 4) {
            Tape(forecast.usedPercent / 100, projection: projected.map { $0 / 100 }, status: status)
                .padding(.bottom, 4)
            Group {
                Text(ForecastText.usage(forecast, now: now))
                if let pace = ForecastText.pace(forecast, now: now) {
                    Text(pace)
                }
                if let range = ForecastText.range(forecast, now: now) {
                    Text(range)
                }
                if let note {
                    Text(note)
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
