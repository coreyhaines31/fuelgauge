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
            checkForUpdates: { [updater] in updater.checkForUpdates() }
        )
        model.onChange = { [weak self] in
            guard let self else { return }
            statusItemController?.update()
            #if DEBUG
            if DemoMode.isOn { return }
            #endif
            alerts.check(model.forecasts)
        }
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.statusItemController?.update() }
        }
        model.start()
        #if DEBUG
        if DemoMode.isOn, let url = DemoMode.snapshotURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DemoMode.snapshot(model: model, updater: self.updater, to: url)
            }
        }
        #endif
    }

    private func makeModel() -> UsageModel {
        #if DEBUG
        if DemoMode.isOn {
            DemoMode.prepare()
            return UsageModel(supportFolder: DemoMode.folder, readsLiveData: false)
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
