import Foundation

enum Preferences {
    static let appliedLaunchAtLoginDefaultKey = "appliedLaunchAtLoginDefault"

    static var appliedLaunchAtLoginDefault: Bool {
        get { UserDefaults.standard.bool(forKey: appliedLaunchAtLoginDefaultKey) }
        set { UserDefaults.standard.set(newValue, forKey: appliedLaunchAtLoginDefaultKey) }
    }
}
