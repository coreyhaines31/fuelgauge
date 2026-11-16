import FuelGaugeCore
import PanelKit
import SwiftUI

/// What opens from the menu bar: the fuel meter on the most urgent limit, the verdict, then a section per tool,
/// most urgent first, plus setup for tools that need it.
struct PanelView: View {
    let model: UsageModel
    let openSettings: () -> Void
    let checkForUpdates: () -> Void
    var openResetSettings: (() -> Void)?
    var openUsage: () -> Void = {}
    var openForecasts: () -> Void = {}
    @State private var setupError: String?
    @State private var cardsHeight: CGFloat = 400
    @BrushedTheme private var theme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Panel(accent: PanelAccent.fuelGauge) {
                fascia(now: context.date)
                verdict(now: context.date)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if needsClaudeSetup {
                            claudeSetup
                        }
                        ForEach(groups, id: \.provider) { group in
                            ToolCard(provider: group.provider, forecasts: group.forecasts, now: context.date,
                                     chartKey: chartKey, model: model,
                                     openSettings: openResetSettings ?? openSettings, openUsage: openUsage)
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardsHeight = $0 }
                }
                .frame(height: min(cardsHeight, max(240, (NSScreen.main?.visibleFrame.height ?? 900) - 200)))
                links
            } footer: {
                Footer(appName: Brand.name, openSettings: openSettings, quit: { NSApp.terminate(nil) })
            }
        }
    }

    // MARK: Fascia and verdict

    private func fascia(now: Date) -> some View {
        let urgent = model.mostUrgent
        let fuelLeft = urgent.map { min(max(1 - $0.usedPercent / 100, 0), 1) } ?? 0
        return Fascia(
            nameplate: "Fuel",
            timestamp: model.updatedAt.map { "Updated \(ForecastText.time($0, now: now))" },
            detail: urgent.map { "Most urgent · \($0.windowName)" },
            label: urgent?.key.provider.name
        ) {
            Meter(
                MeterConfig(
                    majorTicks: 4, minorTicks: 4, zones: [0...0.12],
                    labels: [.init(0, "E"), .init(0.25, "¼"), .init(0.5, "½"), .init(0.75, "¾"), .init(1, "F")],
                    innerLabels: [.init(0, "0"), .init(0.5, "50"), .init(1, "100%")],
                    word: "LIMIT", accessibilityLabel: "Fuel left in the most urgent limit"
                ),
                value: fuelLeft,
                accessibilityValue: urgent.map {
                    "\(ForecastText.percent(100 - $0.usedPercent)) left in \($0.key.provider.name) \($0.windowName)"
                } ?? "No reading"
            )
        }
    }

    @ViewBuilder private func verdict(now: Date) -> some View {
        if !model.forecasts.isEmpty {
            // The summary's " · N more running short" tail reads better as the sentence under the title.
            let parts = ForecastText.summary(model.forecasts, now: now).components(separatedBy: " · ")
            let rest = parts.dropFirst().joined(separator: ". ")
            Verdict(parts[0], message: rest.isEmpty ? nil : rest.prefix(1).uppercased() + rest.dropFirst() + ".",
                    status: summaryStatus.status, statusLabel: summaryStatus.label)
        } else if groups.isEmpty {
            Verdict("No readings yet", message: emptyDetail, status: .off, statusLabel: "No readings")
        }
    }

    /// The status light that replaces the old summary icon: coloured only when a limit is short or the reading
    /// is good.
    private var summaryStatus: (status: PanelStatus, label: String) {
        switch model.mostUrgent?.verdict {
        case .limitReached: (.stop, "Limit reached")
        case .runsOut: (.caution, "Running short")
        case .makesIt: (.go, "Makes it")
        case .reset: (.off, "Reset")
        case .stale: (.off, "Needs a reading")
        case .learning, nil: (.off, "Learning")
        }
    }

    // MARK: Tools

    private struct Group {
        let provider: Provider
        let forecasts: [Forecast]
    }

    /// A section per tool, the tool with the most urgent limit first; inside, the shortest window first.
    private var groups: [Group] {
        var order: [Provider] = []
        for forecast in model.byUrgency where !order.contains(forecast.key.provider) {
            order.append(forecast.key.provider)
        }
        for provider in [Provider.claude, .codex] where !order.contains(provider) {
            if model.visibleUsage.contains(where: { $0.provider == provider }) { order.append(provider) }
        }
        return order.map { provider in
            Group(provider: provider, forecasts: model.forecasts
                .filter { $0.key.provider == provider }
                .sorted { ($0.windowMinutes ?? .max) < ($1.windowMinutes ?? .max) })
        }
    }

    /// Only the most urgent window that's running short gets a chart, so the panel stays short.
    private var chartKey: LimitKey? {
        model.byUrgency.first(where: \.isShort)?.key
    }

    // MARK: Claude setup

    private var needsClaudeSetup: Bool {
        model.installedProviders.contains(.claude) && Tracking.isEnabled(.claude) && model.claudeStatusLine != .on
    }

    private var claudeSetup: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("See your Claude Code limits")
                .font(PanelFont.body(13, .semibold))
                .foregroundStyle(theme.ink)
            Text(claudeSetupDetail)
                .font(PanelFont.body(11.5))
                .foregroundStyle(theme.sub)
                .fixedSize(horizontal: false, vertical: true)
            if let setupError {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    StatusLight(.stop, "Error")
                    Text(setupError)
                        .font(PanelFont.body(11.5))
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button("Turn On") {
                do {
                    try model.setClaudeStatusLine(on: true)
                    setupError = nil
                } catch {
                    setupError = "Couldn't update Claude Code's settings: \(error.localizedDescription)"
                }
            }
            .buttonStyle(PanelButtonStyle(.primary))
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.field, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(theme.line, lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var claudeSetupDetail: String {
        let base = "Claude Code shares its limits with its status line. Fuel Gauge adds a forecast there and "
            + "reads each update. Nothing goes online."
        if case .otherCommand = model.claudeStatusLine {
            return base + " Your current status line keeps showing underneath."
        }
        return base
    }

    // MARK: Empty state and links

    private var emptyDetail: String {
        let names = Tracking.enabled(installed: model.installedProviders).map(\.name)
        guard !names.isEmpty else {
            return "Fuel Gauge works with Claude Code, Codex, Grok Bot, and Cursor. Install one, or turn one on in "
                + "Settings."
        }
        return "Readings appear as you use \(ListFormatter.localizedString(byJoining: names))."
    }

    private var links: some View {
        LinkBar {
            Button("View usage", action: openUsage)
            Button("Forecast details", action: openForecasts)
            Button("Check for Updates…", action: checkForUpdates)
        }
    }
}
