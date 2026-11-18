import FuelGaugeCore
import PanelKit
import SwiftUI

/// What opens from the menu bar: the fuel meter on the most urgent limit, the verdict, then a section per tool
/// account (a tool's accounts side by side), most urgent first, plus setup for accounts that need it.
struct PanelView: View {
    let model: UsageModel
    let openSettings: () -> Void
    let checkForUpdates: () -> Void
    var openResetSettings: (() -> Void)?
    var openUsage: () -> Void = {}
    var openForecasts: () -> Void = {}
    @State private var setupError: (account: String, text: String)?
    @State private var cardsHeight: CGFloat = 400
    @Environment(\.panelTheme) private var theme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Panel(accent: PanelAccent.fuelGauge) {
                fascia(now: context.date)
                verdict(now: context.date)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(model.claudeAccountsNeedingSetup) { account in
                            claudeSetup(account)
                        }
                        ForEach(groups, id: \.id) { group in
                            ToolCard(provider: group.provider, forecasts: group.forecasts, now: context.date,
                                     chartKey: chartKey, account: group.account, model: model,
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
            label: urgent?.sourceLabel
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
                    "\(ForecastText.percent(100 - $0.usedPercent)) left in \($0.sourceLabel) \($0.windowName)"
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
        /// Nil for a tool without accounts (Grok Bot, Cursor).
        let account: Account?
        let forecasts: [Forecast]

        var id: String { account?.id ?? provider.rawValue }
    }

    /// A section per tool account. Tools go most urgent first, and a tool's accounts stay together, most urgent
    /// first; inside each, the shortest window first.
    private var groups: [Group] {
        var order: [Provider] = []
        var accountOrder: [Provider: [String?]] = [:]
        func note(_ provider: Provider, _ slug: String?) {
            if !order.contains(provider) { order.append(provider) }
            if accountOrder[provider]?.contains(slug) != true { accountOrder[provider, default: []].append(slug) }
        }
        for forecast in model.byUrgency { note(forecast.key.provider, forecast.key.account) }
        for provider in Account.multiAccountProviders {
            for account in model.accounts(for: provider)
            where model.visibleUsage.contains(where: { $0.provider == provider && $0.account == account.slug }) {
                note(provider, account.slug)
            }
        }
        return order.flatMap { provider in
            (accountOrder[provider] ?? []).compactMap { slug -> Group? in
                let account = model.accounts.account(provider, slug: slug)
                if Account.multiAccountProviders.contains(provider), account == nil { return nil }
                return Group(provider: provider, account: account, forecasts: model.forecasts
                    .filter { $0.key.provider == provider && $0.key.account == slug }
                    .sorted { ($0.windowMinutes ?? .max) < ($1.windowMinutes ?? .max) })
            }
        }
    }

    /// Only the most urgent window that's running short gets a chart, so the panel stays short.
    private var chartKey: LimitKey? {
        model.byUrgency.first(where: \.isShort)?.key
    }

    // MARK: Claude setup

    private func claudeSetup(_ account: Account) -> some View {
        let error = setupError.flatMap { $0.account == account.id ? $0.text : nil }
        let detail = claudeSetupDetail(account)
        let title = model.accounts.label(provider: .claude, slug: account.slug)
            .map { "See \($0)'s Claude Code limits" } ?? "See your Claude Code limits"
        return Notice(title, message: error.map { detail + "\n\n" + $0 } ?? detail,
                      status: error == nil ? .caution : .stop) {
            Button("Turn On") {
                do {
                    try model.setClaudeStatusLine(on: true, account: account)
                    setupError = nil
                } catch {
                    setupError = (account.id, "Couldn't update Claude Code's settings: \(error.localizedDescription)")
                }
            }
            .buttonStyle(.panelCompact)
        }
    }

    private func claudeSetupDetail(_ account: Account) -> String {
        let base = "Claude Code shares its limits with its status line. Fuel Gauge adds a forecast there and "
            + "reads each update. Nothing goes online."
        if case .otherCommand = model.claudeStatusLine(for: account) {
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
