import Foundation

/// Which tools are installed and which ones the person tracks. The app's Settings write the choice to its
/// defaults; the `fuelgauge` command reads the same defaults, so both agree.
public enum Tracking {
    public static let disabledProvidersKey = "disabledProviders"

    /// Tools that look installed on this Mac.
    public static func installed() -> [Provider] {
        var providers: [Provider] = []
        if ClaudeSettings().isInstalled { providers.append(.claude) }
        if CodexLogReader().isInstalled { providers.append(.codex) }
        if GrokBotReader().isInstalled { providers.append(.grokBot) }
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
        !(defaults.stringArray(forKey: disabledProvidersKey) ?? []).contains(provider.rawValue)
    }

    public static func enabled(installed: [Provider] = installed()) -> [Provider] {
        installed.filter(isEnabled)
    }

    public static func setEnabled(_ provider: Provider, _ enabled: Bool) {
        var disabled = Set(defaults.stringArray(forKey: disabledProvidersKey) ?? [])
        if enabled {
            disabled.remove(provider.rawValue)
        } else {
            disabled.insert(provider.rawValue)
        }
        defaults.set(disabled.sorted(), forKey: disabledProvidersKey)
    }
}
