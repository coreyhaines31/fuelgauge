import AppKit
import FuelGaugeCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let updater = Updater()
    private var model: UsageModel?
    private var statusItemController: StatusItemController?
    private var settingsWindow: SettingsWindow?
    private let alerts = Alerts()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        #if !DEBUG
        applyLaunchAtLoginDefault()
        #endif
        let model = makeModel()
        self.model = model
        let settingsWindow = SettingsWindow(updater: updater, model: model)
        self.settingsWindow = settingsWindow
        statusItemController = StatusItemController(
            model: model,
            openSettings: { settingsWindow.show() },
            openResetSettings: { settingsWindow.show(tab: "Resets") },
            checkForUpdates: { [updater] in updater.checkForUpdates() }
        )
        model.onChange = { [weak self] in self?.statusItemController?.update() }
        model.onRefresh = { [weak self] forecasts in
            #if DEBUG
            if DemoMode.isOn { return }
            #endif
            self?.alerts.check(forecasts)
        }
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.statusItemController?.update() }
        }
        model.start()
        #if DEBUG
        if let url = DemoMode.snapshotURL {
            // Live data needs a moment for the first read of Codex's logs.
            DispatchQueue.main.asyncAfter(deadline: .now() + (DemoMode.isOn ? 0.5 : 3)) {
                DemoMode.snapshot(model: model, updater: self.updater, to: url)
            }
        }
        #endif
    }

    private func makeModel() -> UsageModel {
        #if DEBUG
        if DemoMode.isOn {
            DemoMode.prepare()
            return UsageModel(supportFolder: DemoMode.folder, readsLiveData: false,
                              resetCredits: DemoMode.resetCredits)
        }
        #endif
        return UsageModel()
    }

    /// Turns on launch at login once, so readings keep coming after a restart. Tries again next launch if it fails.
    /// Debug builds skip it so a DerivedData copy never becomes the login item.
    private func applyLaunchAtLoginDefault() {
        guard !Preferences.appliedLaunchAtLoginDefault else { return }
        guard (try? SMAppService.mainApp.register()) != nil else { return }
        Preferences.appliedLaunchAtLoginDefault = true
    }
}
