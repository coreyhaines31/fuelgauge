import AppKit
import FuelGaugeCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let updater = Updater()
    private var model: UsageModel?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.registerDefaults()
        #if !DEBUG
        applyLaunchAtLoginDefault()
        #endif
        let model = makeModel()
        self.model = model
        statusItemController = StatusItemController(
            model: model,
            openSettings: {},
            checkForUpdates: { [updater] in updater.checkForUpdates() }
        )
        model.onChange = { [weak self] in self?.statusItemController?.update() }
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.statusItemController?.update() }
        }
        model.start()
        #if DEBUG
        if DemoMode.isOn, let url = DemoMode.snapshotURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { DemoMode.snapshot(model: model, to: url) }
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
