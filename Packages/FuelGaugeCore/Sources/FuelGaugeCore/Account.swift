import Foundation

/// One sign-in of a tool. Claude Code and Codex keep each sign-in in its own config folder
/// (`CLAUDE_CONFIG_DIR=~/.claude-work claude`, `CODEX_HOME=~/.codex-work codex`), so a folder is an account.
/// The default account is the folder Fuel Gauge always read; its readings, alert state, and recorded resets
/// keep the names they had before there were other accounts.
public struct Account: Codable, Hashable, Sendable, Identifiable {
    public let provider: Provider
    /// Nil for the default account. Otherwise short, stable, and safe in file names: `work_1a2b3c`.
    public let slug: String?
    /// The folder exactly as the tool is given it. Claude Code keys its Keychain sign-in on this string, so it's
    /// kept as typed (with `~` expanded), never resolved through symlinks.
    public let folderPath: String
    public var name: String

    public init(provider: Provider, slug: String?, folderPath: String, name: String) {
        self.provider = provider
        self.slug = slug
        self.folderPath = folderPath
        self.name = name
    }

    /// Tools that keep one account per config folder.
    public static let multiAccountProviders: [Provider] = [.claude, .codex]

    public var id: String { Self.qualifiedID(provider: provider, slug: slug) }
    public var folder: URL { URL(filePath: folderPath) }
    public var isDefault: Bool { slug == nil }

    /// "claude" for the default account, "claude@work_1a2b3c" for another.
    public static func qualifiedID(provider: Provider, slug: String?) -> String {
        slug.map { "\(provider.rawValue)@\($0)" } ?? provider.rawValue
    }

    /// The environment variable that points the tool at a config folder.
    public static func folderVariable(for provider: Provider) -> String? {
        switch provider {
        case .claude: "CLAUDE_CONFIG_DIR"
        case .codex: "CODEX_HOME"
        default: nil
        }
    }

    /// The folder the tool uses when nothing points it elsewhere: its variable if set, else `~/.claude` or
    /// `~/.codex`.
    public static func defaultFolder(for provider: Provider,
                                     environment: [String: String] = ProcessInfo.processInfo.environment,
                                     home: URL = .homeDirectory) -> String {
        if let variable = folderVariable(for: provider), let value = environment[variable], !value.isEmpty {
            return standardized(value, home: home)
        }
        return home.appending(path: provider == .codex ? ".codex" : ".claude").path
    }

    public static func defaultAccount(_ provider: Provider,
                                      environment: [String: String] = ProcessInfo.processInfo.environment,
                                      home: URL = .homeDirectory) -> Account {
        Account(provider: provider, slug: nil,
                folderPath: defaultFolder(for: provider, environment: environment, home: home), name: "Main")
    }

    /// Another account, for a folder that isn't the default one. The slug comes from the folder, so the same
    /// folder always gets the same one, even from the `fuelgauge` command before it's added in Settings.
    public static func make(_ provider: Provider, folder path: String, home: URL = .homeDirectory) -> Account {
        let folder = standardized(path, home: home)
        let stem = stem(of: folder, provider: provider)
        let slugStem = String(stem.lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }.prefix(16))
        let slug = (slugStem.isEmpty ? "account" : slugStem) + "_" + hash(folder)
        let name = stem.isEmpty
            ? URL(filePath: folder).lastPathComponent : stem.prefix(1).uppercased() + stem.dropFirst()
        return Account(provider: provider, slug: slug, folderPath: folder, name: name)
    }

    /// "work" for `~/.claude-work`; the folder's name when it doesn't start with the tool's.
    private static func stem(of folder: String, provider: Provider) -> String {
        let name = URL(filePath: folder).lastPathComponent
        let prefix = provider == .codex ? ".codex" : ".claude"
        guard name.hasPrefix(prefix) else { return name.hasPrefix(".") ? String(name.dropFirst()) : name }
        return String(name.dropFirst(prefix.count).drop { "-_. ".contains($0) })
    }

    /// `~` expanded, `.`/`..` and doubled slashes folded, no trailing slash.
    public static func standardized(_ path: String, home: URL = .homeDirectory) -> String {
        var path = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if path == "~" {
            path = home.path
        } else if path.hasPrefix("~/") {
            path = home.path + path.dropFirst(1)
        }
        var standard = URL(filePath: path).standardizedFileURL.path
        while standard.count > 1 && standard.hasSuffix("/") { standard.removeLast() }
        return standard
    }

    /// Six hex digits of FNV-1a, so two folders with the same name get different slugs.
    private static func hash(_ text: String) -> String {
        var value: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value = value &* 0x0000_0100_0000_01b3
        }
        return String(format: "%06x", value & 0xFF_FFFF)
    }

    // MARK: Where an account's things live

    /// What to set for a child process so the tool uses this account. Empty for the default account, which runs
    /// exactly as before: Claude Code keys the default Keychain sign-in on `CLAUDE_CONFIG_DIR` being unset.
    public var environment: [String: String] {
        guard let slug, slug.isEmpty == false, let variable = Self.folderVariable(for: provider) else { return [:] }
        return [variable: folderPath]
    }

    /// A support file for this account: `claude-usage.json`, or `claude-usage-work_1a2b3c.json`.
    public func supportFile(_ base: String, extension ext: String, in folder: URL = Brand.supportFolder) -> URL {
        folder.appending(path: slug.map { "\(base)-\($0).\(ext)" } ?? "\(base).\(ext)")
    }

    /// A defaults key for this account: `claudeResetCount`, or `claudeResetCount.work_1a2b3c`.
    public func defaultsKey(_ base: String) -> String {
        slug.map { "\(base).\($0)" } ?? base
    }

    /// Whether the folder holds a sign-in, settings, or usage logs, rather than being some other folder that
    /// happens to share the name.
    public var hasAccountData: Bool {
        let markers = provider == .codex
            ? ["auth.json", "config.toml", "sessions"]
            : [".claude.json", ".credentials.json", "settings.json", "projects"]
        return markers.contains { FileManager.default.fileExists(atPath: folder.appending(path: $0).path) }
    }

    /// Who's signed in, when the tool says so on disk without credentials: "ann@example.com · Max". Claude
    /// Code keeps this in `.claude.json` (in the home folder for the default account). Codex keeps its email
    /// only inside its tokens, so it has none.
    public func signedInAs(home: URL = .homeDirectory,
                           environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        guard provider == .claude else { return nil }
        let usesHome = isDefault && (environment["CLAUDE_CONFIG_DIR"] ?? "").isEmpty
        let url = usesHome ? home.appending(path: ".claude.json") : folder.appending(path: ".claude.json")
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let account = config["oauthAccount"] as? [String: Any],
              let email = Self.clean(account["emailAddress"]) else { return nil }
        let organization = Self.clean(account["organizationName"]).flatMap { $0.contains("@") ? nil : $0 }
        let plan = Self.clean(account["planDisplayName"])
        return ([email] + [organization, plan].compactMap { $0 }).joined(separator: " · ")
    }

    private static func clean(_ value: Any?) -> String? {
        guard let text = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty, text.count <= 120 else { return nil }
        return text
    }
}

/// The accounts the person tracks, saved in the app's defaults so the `fuelgauge` command sees the same list.
/// A Mac that never added one has nothing saved, and gets each tool's default account: the folder Fuel Gauge
/// always read, under the names it always used.
public struct AccountList: Equatable, Sendable {
    public static let defaultsKey = "accounts"

    public private(set) var accounts: [Account]

    public init(_ accounts: [Account] = []) {
        self.accounts = []
        for account in accounts { add(account) }
    }

    /// The saved list, with a default account for each tool that has none saved. `environment` decides the
    /// default folder only when none is saved; the command passes an empty one, since its `CLAUDE_CONFIG_DIR`
    /// names the account it's running for, not the default.
    public static func load(from defaults: UserDefaults = Tracking.defaults,
                            environment: [String: String] = ProcessInfo.processInfo.environment,
                            home: URL = .homeDirectory) -> AccountList {
        let saved = defaults.data(forKey: defaultsKey)
            .flatMap { try? JSONDecoder().decode([Account].self, from: $0) } ?? []
        var list = AccountList(saved)
        for provider in Account.multiAccountProviders where list.defaultAccount(provider) == nil {
            list.accounts.insert(.defaultAccount(provider, environment: environment, home: home), at: 0)
        }
        list.sort()
        return list
    }

    public func save(to defaults: UserDefaults = Tracking.defaults) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    /// A tool's accounts, the default one first.
    public func accounts(for provider: Provider) -> [Account] {
        accounts.filter { $0.provider == provider }
    }

    public func defaultAccount(_ provider: Provider) -> Account? {
        accounts.first { $0.provider == provider && $0.isDefault }
    }

    public func account(_ provider: Provider, slug: String?) -> Account? {
        accounts.first { $0.provider == provider && $0.slug == slug }
    }

    /// The account a config folder belongs to: a saved one, else a new one (not saved) for that folder.
    public func account(_ provider: Provider, folder path: String, home: URL = .homeDirectory) -> Account {
        let folder = Account.standardized(path, home: home)
        if let saved = accounts.first(where: { $0.provider == provider && $0.folderPath == folder }) { return saved }
        return Account.make(provider, folder: folder, home: home)
    }

    /// The account a tool started with `environment` runs as: its config folder variable picks it, and no
    /// variable means the default account.
    public func account(_ provider: Provider, environment: [String: String],
                        home: URL = .homeDirectory) -> Account? {
        guard let variable = Account.folderVariable(for: provider),
              let value = environment[variable], !value.isEmpty else { return defaultAccount(provider) }
        let account = account(provider, folder: value, home: home)
        // Pointing the variable at the tool's usual folder is still the default account.
        let usual = Account.defaultFolder(for: provider, environment: [:], home: home)
        return account.slug != nil && account.folderPath == usual ? defaultAccount(provider) : account
    }

    /// Adds an account, or renames the saved one for the same folder.
    public mutating func add(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.provider == account.provider && $0.slug == account.slug }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        sort()
    }

    /// Removes another account. The default one stays; turn the tool off to stop tracking it.
    public mutating func remove(_ account: Account) {
        guard !account.isDefault else { return }
        accounts.removeAll { $0.provider == account.provider && $0.slug == account.slug }
    }

    public mutating func rename(_ account: Account, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index].name = String(trimmed.prefix(40))
    }

    /// The account name to show beside a limit, or nil when its tool has only one account, so a Mac with one
    /// account per tool reads exactly as before.
    public func label(provider: Provider, slug: String?) -> String? {
        guard accounts(for: provider).count > 1 else { return nil }
        return account(provider, slug: slug)?.name ?? slug
    }

    /// The forecasts with their account names filled in, for every tool with more than one account.
    public func label(_ forecasts: [Forecast]) -> [Forecast] {
        forecasts.map { forecast in
            var labelled = forecast
            labelled.accountName = label(provider: forecast.key.provider, slug: forecast.key.account)
            return labelled
        }
    }

    /// Folders in the home folder that look like other accounts (`~/.claude-work`, `~/.codex-client`) and
    /// aren't tracked yet. `~/.claude-worktrees` and folders without account data are skipped.
    public func candidates(home: URL = .homeDirectory) -> [Account] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: home.path)) ?? []
        let skipped: Set<String> = [".claude-worktrees"]
        return names.sorted().compactMap { name -> Account? in
            guard !skipped.contains(name) else { return nil }
            let provider: Provider
            if name.hasPrefix(".claude"), name.count > 7,
               "-_".contains(name[name.index(name.startIndex, offsetBy: 7)]) {
                provider = .claude
            } else if name.hasPrefix(".codex"), name.count > 6,
                      "-_".contains(name[name.index(name.startIndex, offsetBy: 6)]) {
                provider = .codex
            } else {
                return nil
            }
            var isDirectory: ObjCBool = false
            let path = home.appending(path: name).path
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue
            else { return nil }
            let account = account(provider, folder: path, home: home)
            guard !accounts.contains(where: { $0.provider == provider && $0.folderPath == account.folderPath }),
                  account.hasAccountData else { return nil }
            return account
        }
    }

    private mutating func sort() {
        accounts.sort { lhs, rhs in
            if lhs.provider != rhs.provider { return lhs.provider < rhs.provider }
            if lhs.isDefault != rhs.isDefault { return lhs.isDefault }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
