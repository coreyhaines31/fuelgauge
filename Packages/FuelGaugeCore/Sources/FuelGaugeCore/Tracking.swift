import Foundation

/// Which tools are installed and which ones the person tracks. The app's Settings write the choice to its
/// defaults; the `fuelgauge` command reads the same defaults, so both agree.
public enum Tracking {
    public static let disabledProvidersKey = "disabledProviders"
    public static let enabledOptInProvidersKey = "enabledOptInProviders"

    /// Tools that go online to read usage stay off until turned on.
    public static let optIn: Set<Provider> = [.cursor]

    /// Tools that look installed on this Mac.
    public static func installed() -> [Provider] {
        var providers: [Provider] = []
        if ClaudeSettings().isInstalled { providers.append(.claude) }
        if CodexLogReader().isInstalled { providers.append(.codex) }
        if GrokBotReader().isInstalled { providers.append(.grokBot) }
        if CursorReader().isInstalled { providers.append(.cursor) }
        return providers
    }

    /// The app's defaults, whether this runs in the app or in the command.
    public static var defaults: UserDefaults {
        Bundle.main.bundleIdentifier == Brand.bundleIdentifier
            ? .standard
            : UserDefaults(suiteName: Brand.bundleIdentifier) ?? .standard
    }

    /// Tools are tracked unless turned off, so a newly installed tool shows up by itself.
    public static func isEnabled(_ provider: Provider) -> Bool {
        if optIn.contains(provider) {
            return (defaults.stringArray(forKey: enabledOptInProvidersKey) ?? []).contains(provider.rawValue)
        }
        return !(defaults.stringArray(forKey: disabledProvidersKey) ?? []).contains(provider.rawValue)
    }

    public static func enabled(installed: [Provider] = installed()) -> [Provider] {
        installed.filter(isEnabled)
    }

    public static func setEnabled(_ provider: Provider, _ enabled: Bool) {
        let key = optIn.contains(provider) ? enabledOptInProvidersKey : disabledProvidersKey
        // The opt-in list holds tools that are on; the other list holds tools that are off.
        let listed = optIn.contains(provider) ? enabled : !enabled
        var names = Set(defaults.stringArray(forKey: key) ?? [])
        if listed {
            names.insert(provider.rawValue)
        } else {
            names.remove(provider.rawValue)
        }
        defaults.set(names.sorted(), forKey: key)
    }
}
