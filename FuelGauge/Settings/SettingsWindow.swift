import AppKit
import SwiftUI

/// Standard macOS settings window: icon tabs in the toolbar, sized to each pane.
@MainActor
final class SettingsWindow {
    static let paneWidth: CGFloat = 520

    private let updater: Updater
    private let model: UsageModel
    private var window: NSWindow?

    init(updater: Updater, model: UsageModel) {
        self.updater = updater
        self.model = model
    }

    func show(tab: String? = nil) {
        if window == nil {
            window = makeWindow()
        }
        if let tab, let tabs = window?.contentViewController as? NSTabViewController,
           let index = tabs.tabViewItems.firstIndex(where: { $0.label == tab }) {
            tabs.selectedTabViewItemIndex = index
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let tabs = SettingsTabController()
        tabs.tabStyle = .toolbar
        tabs.add("General", symbol: "gearshape", view: GeneralSettingsView(updater: updater))
        tabs.add("Tools", symbol: "square.stack.3d.up", view: ToolsSettingsView(model: model))
        tabs.add("Resets", symbol: "arrow.counterclockwise", view: ResetsSettingsView(model: model))
        tabs.add("Alerts", symbol: "bell", view: AlertsSettingsView())
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

private final class SettingsTabController: NSTabViewController {
    func add(_ title: String, symbol: String, view: some View) {
        let controller = NSHostingController(rootView: view.frame(width: SettingsWindow.paneWidth))
        controller.sizingOptions = .preferredContentSize
        controller.title = title
        let item = NSTabViewItem(viewController: controller)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        addTabViewItem(item)
    }
}
