import AppKit
import FuelGaugeCore
import SwiftUI

/// The menu bar gauge and the panel it opens.
@MainActor
final class StatusItemController {
    private static let autosaveName = "FuelGauge"
    private let item: NSStatusItem
    private let popover = NSPopover()
    private let model: UsageModel
    private var hosting: NSHostingController<PanelView>?

    init(model: UsageModel, openSettings: @escaping () -> Void, openResetSettings: @escaping () -> Void,
         checkForUpdates: @escaping () -> Void) {
        self.model = model
        // New status items start at the far left on recent macOS, which is off-screen on a crowded menu bar.
        UserDefaults.standard.register(defaults: ["NSStatusItem Preferred Position \(Self.autosaveName)": 1])
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = Self.autosaveName
        item.button?.imagePosition = .imageLeading
        item.button?.target = self
        item.button?.action = #selector(toggle)

        let panel = PanelView(model: model, openSettings: { [weak popover] in
            popover?.performClose(nil)
            openSettings()
        }, checkForUpdates: checkForUpdates, openResetSettings: { [weak popover] in
            popover?.performClose(nil)
            openResetSettings()
        })
        let hosting = NSHostingController(rootView: panel)
        hosting.sizingOptions = .preferredContentSize
        self.hosting = hosting
        popover.contentViewController = hosting
        popover.behavior = .transient
        update()
    }

    var button: NSStatusBarButton? { item.button }

    func update() {
        let urgent = model.mostUrgent
        let tint: NSColor? = switch urgent?.verdict {
        case .limitReached: .systemRed
        case .runsOut: .systemOrange
        default: nil
        }
        item.button?.image = FuelGlyph.image(fuelLeft: urgent.map { 1 - $0.usedPercent / 100 }, tint: tint)
        item.button?.title = title(for: urgent)
        item.button?.toolTip = urgent.map { "\($0.key.provider.name) \($0.windowName): \(ForecastText.headline($0))" }
    }

    private func title(for forecast: Forecast?) -> String {
        guard let forecast else { return "" }
        switch Preferences.menuBarText {
        case .none:
            return ""
        case .percentUsed:
            return " " + ForecastText.percent(forecast.usedPercent)
        case .timeLeft:
            switch forecast.verdict {
            case .runsOut(let at, _, _): return " " + ForecastText.duration(at.timeIntervalSinceNow)
            case .limitReached: return " out"
            default: return ""
            }
        }
    }

    @objc private func toggle() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show()
        }
    }

    func show() {
        guard let button = item.button else { return }
        model.refresh()
        if let view = hosting?.view {
            popover.contentSize = view.fittingSize
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}
