import Foundation
import FuelGaugeCore

enum MenuBarText: String, CaseIterable, Identifiable {
    case none
    case percentUsed
    case timeLeft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Pump only"
        case .percentUsed: "Percent used"
        case .timeLeft: "Time to run out"
        }
    }
}

enum Preferences {
    static let appliedLaunchAtLoginDefaultKey = "appliedLaunchAtLoginDefault"
    static let menuBarTextKey = "menuBarText"
    static let alertWhenShortKey = "alertWhenShort"
    static let alertThresholdsKey = "alertThresholds"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            menuBarTextKey: MenuBarText.none.rawValue,
            alertWhenShortKey: true,
            alertThresholdsKey: [80, 95],
            ResetPreferences.codexEnabled: true
        ])
    }

    static var appliedLaunchAtLoginDefault: Bool {
        get { UserDefaults.standard.bool(forKey: appliedLaunchAtLoginDefaultKey) }
        set { UserDefaults.standard.set(newValue, forKey: appliedLaunchAtLoginDefaultKey) }
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
