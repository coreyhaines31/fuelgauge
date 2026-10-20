import AppKit
import FuelGaugeCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let updater = Updater()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if !DEBUG
        applyLaunchAtLoginDefault()
        #endif
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "fuelpump", accessibilityDescription: Brand.name)
        let menu = NSMenu()
        menu.addItem(ClosureMenuItem("Check for Updates…") { [updater] in updater.checkForUpdates() })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem("Quit \(Brand.name)", keyEquivalent: "q") { NSApp.terminate(nil) })
        item.menu = menu
        statusItem = item
    }

    /// Turns on launch at login once, so readings keep coming after a restart. Tries again next launch if it fails.
    /// Debug builds skip it so a DerivedData copy never becomes the login item.
    private func applyLaunchAtLoginDefault() {
        guard !Preferences.appliedLaunchAtLoginDefault else { return }
        guard (try? SMAppService.mainApp.register()) != nil else { return }
        Preferences.appliedLaunchAtLoginDefault = true
    }
}
