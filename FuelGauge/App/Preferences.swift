import Foundation
import FuelGaugeCore

enum MenuBarText: String, CaseIterable, Identifiable {
    case none
    case percentUsed
    case timeLeft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Gauge only"
        case .percentUsed: "Percent used"
        case .timeLeft: "Time to run out"
        }
    }
}

enum Preferences {
    static let appliedLaunchAtLoginDefaultKey = "appliedLaunchAtLoginDefault"
    static let disabledProvidersKey = "disabledProviders"
    static let menuBarTextKey = "menuBarText"
    static let alertWhenShortKey = "alertWhenShort"
    static let alertThresholdsKey = "alertThresholds"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            menuBarTextKey: MenuBarText.none.rawValue,
            alertWhenShortKey: true,
            alertThresholdsKey: [80, 95]
        ])
    }

    static var appliedLaunchAtLoginDefault: Bool {
        get { UserDefaults.standard.bool(forKey: appliedLaunchAtLoginDefaultKey) }
        set { UserDefaults.standard.set(newValue, forKey: appliedLaunchAtLoginDefaultKey) }
    }

    /// Tools are on unless turned off, so a newly installed tool shows up by itself.
    static func enabledProviders(installed: [Provider]) -> [Provider] {
        let disabled = Set(UserDefaults.standard.stringArray(forKey: disabledProvidersKey) ?? [])
        return installed.filter { !disabled.contains($0.rawValue) }
    }

    static func isEnabled(_ provider: Provider) -> Bool {
        !(UserDefaults.standard.stringArray(forKey: disabledProvidersKey) ?? []).contains(provider.rawValue)
    }

    static func setEnabled(_ provider: Provider, _ enabled: Bool) {
        var disabled = Set(UserDefaults.standard.stringArray(forKey: disabledProvidersKey) ?? [])
        if enabled {
            disabled.remove(provider.rawValue)
        } else {
            disabled.insert(provider.rawValue)
        }
        UserDefaults.standard.set(disabled.sorted(), forKey: disabledProvidersKey)
    }

    static var menuBarText: MenuBarText {
        MenuBarText(rawValue: UserDefaults.standard.string(forKey: menuBarTextKey) ?? "") ?? .none
    }

    static var alertWhenShort: Bool {
        UserDefaults.standard.bool(forKey: alertWhenShortKey)
    }

    static var alertThresholds: [Int] {
        (UserDefaults.standard.array(forKey: alertThresholdsKey) as? [Int]) ?? [80, 95]
    }
}
