import FuelGaugeCore
import SwiftUI

/// What opens from the menu bar: a card per limit, most urgent first, plus setup for tools that need it.
struct PanelView: View {
    let model: UsageModel
    let openSettings: () -> Void
    let checkForUpdates: () -> Void
    var openResetSettings: (() -> Void)?
    var openUsage: () -> Void = {}
    @State private var setupError: String?
    @State private var cardsHeight: CGFloat = 400

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(alignment: .leading, spacing: 10) {
                header(now: context.date)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if needsClaudeSetup {
                            claudeSetup
                        }
                        if groups.isEmpty {
                            emptyState
                        } else {
                            ForEach(groups, id: \.provider) { group in
                                ToolCard(provider: group.provider, forecasts: group.forecasts, now: context.date,
                                         chartKey: chartKey, model: model,
                                         openSettings: openResetSettings ?? openSettings, openUsage: openUsage)
                            }
                        }
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: PanelHeightKey.self, value: geometry.size.height)
                    })
                }
                .frame(height: min(cardsHeight, max(240, (NSScreen.main?.visibleFrame.height ?? 900) - 200)))
                .onPreferenceChange(PanelHeightKey.self) { cardsHeight = $0 }
                footer
            }
            .padding(14)
            .frame(width: 360)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func header(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(Brand.name).font(.system(size: 15, weight: .semibold))
                Spacer()
                if let updatedAt = model.updatedAt {
                    Text("Updated \(ForecastText.time(updatedAt, now: now))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            if !model.forecasts.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: summarySymbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(summaryTint)
                        .padding(.top, 2)
                        .accessibilityHidden(true)
                    Text(ForecastText.summary(model.forecasts, now: now))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var summarySymbol: String {
        switch model.mostUrgent?.verdict {
        case .limitReached: "exclamationmark.circle.fill"
        case .runsOut: "exclamationmark.triangle.fill"
        case .makesIt: "checkmark.circle"
        case .reset: "arrow.clockwise"
        case .learning, nil: "clock"
        }
    }

    private var summaryTint: Color {
        guard let urgent = model.mostUrgent else { return .secondary }
        return urgent.isShort ? WindowRow.tint(for: urgent.verdict) : .secondary
    }

    private struct Group {
        let provider: Provider
        let forecasts: [Forecast]
    }

    /// A card per tool, the tool with the most urgent limit first; inside, the shortest window first.
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

    private var needsClaudeSetup: Bool {
        model.installedProviders.contains(.claude) && Tracking.isEnabled(.claude) && model.claudeStatusLine != .on
    }

    private var claudeSetup: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("See your Claude Code limits").font(.system(size: 12, weight: .semibold))
            Text(claudeSetupDetail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let setupError {
                Label(setupError, systemImage: "exclamationmark.circle")
                    .font(.system(size: 12)).foregroundStyle(.primary)
            }
            Button("Turn On") {
                do {
                    try model.setClaudeStatusLine(on: true)
                    setupError = nil
                } catch {
                    setupError = "Couldn't update Claude Code's settings: \(error.localizedDescription)"
                }
            }
            .controlSize(.small)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var claudeSetupDetail: String {
        let base = "Claude Code shares its limits with its status line. Fuel Gauge adds a forecast there and "
            + "reads each update. Nothing goes online."
        if case .otherCommand = model.claudeStatusLine {
            return base + " Your current status line keeps showing underneath."
        }
        return base
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No readings yet").font(.system(size: 12, weight: .semibold))
            Text(emptyDetail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var emptyDetail: String {
        let names = Tracking.enabled(installed: model.installedProviders).map(\.name)
        guard !names.isEmpty else {
            return "Fuel Gauge works with Claude Code, Codex, Grok Bot, and Cursor. Install one, or turn one on in "
                + "Settings."
        }
        return "Readings appear as you use \(ListFormatter.localizedString(byJoining: names))."
    }

    private var footer: some View {
        HStack {
            Button("View usage", action: openUsage)
                .buttonStyle(.plain).foregroundStyle(Color.accentColor)
            Spacer()
            Menu {
                Button("Settings…", action: openSettings)
                Button("Check for Updates…", action: checkForUpdates)
                Divider()
                Button("Quit \(Brand.name)") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }
}

private struct PanelHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 400
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
