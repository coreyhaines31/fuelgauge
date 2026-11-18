import Foundation
@testable import FuelGaugeCore
import Testing

/// A throwaway defaults suite, never the app's own.
func temporaryDefaults() -> UserDefaults {
    let name = "FuelGaugeTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@Suite struct AccountTests {
    let home = temporaryFolder()

    private func folder(_ name: String, with marker: String?) throws -> String {
        let url = home.appending(path: name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if let marker { try Data("{}".utf8).write(to: url.appending(path: marker)) }
        return url.path
    }

    @Test func slugsAreStableAndNamedAfterTheFolder() {
        let work = Account.make(.claude, folder: home.appending(path: ".claude-work").path, home: home)
        let again = Account.make(.claude, folder: home.appending(path: ".claude-work/").path, home: home)
        #expect(work.slug == again.slug)
        #expect(work.slug?.hasPrefix("work_") == true)
        #expect(work.slug?.contains("-") == false)
        #expect(work.name == "Work")
        #expect(work.environment == ["CLAUDE_CONFIG_DIR": home.appending(path: ".claude-work").path])
        let elsewhere = Account.make(.claude, folder: "/Volumes/Other/.claude-work", home: home)
        #expect(elsewhere.slug != work.slug)
        let codex = Account.make(.codex, folder: "~/.codex_client", home: home)
        #expect(codex.folderPath == home.appending(path: ".codex_client").path)
        #expect(codex.name == "Client")
        #expect(codex.environment == ["CODEX_HOME": codex.folderPath])
    }

    @Test func theDefaultAccountKeepsTheOldNames() {
        let main = Account.defaultAccount(.claude, environment: [:], home: home)
        #expect(main.slug == nil)
        #expect(main.environment.isEmpty)
        #expect(main.supportFile("claude-usage", extension: "json", in: home).lastPathComponent == "claude-usage.json")
        #expect(main.defaultsKey("claudeResetCount") == "claudeResetCount")
        #expect(LimitKey(provider: .claude, limit: "five_hour").id == "claude/five_hour")
        let work = Account.make(.claude, folder: "~/.claude-work", home: home)
        #expect(work.supportFile("claude-usage", extension: "json", in: home).lastPathComponent
            == "claude-usage-\(work.slug!).json")
        #expect(LimitKey(provider: .claude, limit: "five_hour", account: work.slug).id
            == "claude@\(work.slug!)/five_hour")
    }

    /// A Mac that used Fuel Gauge before accounts existed has no saved list, readings without an account, and
    /// resets and alert state under the old keys. All of it has to land on the default account unchanged.
    @Test func oldSingleAccountDataLoadsIntoTheDefaultAccount() throws {
        let defaults = temporaryDefaults()
        defaults.set(2, forKey: "claudeResetCount")
        defaults.set(1_900_000_000.0, forKey: "claudeResetExpiry")
        defaults.set(3, forKey: "claudeFableResetCount")
        defaults.set(1_800_000_000.0, forKey: "claudeResetsCheckedAt")
        defaults.set(["grok-bot"], forKey: Tracking.disabledProvidersKey)

        let list = AccountList.load(from: defaults, environment: [:], home: home)
        #expect(list.accounts.map(\.slug) == [nil, nil])
        #expect(list.accounts.map(\.provider) == [.claude, .codex])
        let main = try #require(list.defaultAccount(.claude))
        #expect(main.folderPath == home.appending(path: ".claude").path)
        #expect(list.label(provider: .claude, slug: nil) == nil)

        let resets = ClaudeResets.load(from: defaults, account: main)
        #expect(resets == ClaudeResets.load(from: defaults))
        #expect(resets.weekly.available == 2)
        #expect(resets.fable.available == 3)
        #expect(resets.recordedAt == Date(timeIntervalSince1970: 1_800_000_000))

        // A reading line written before accounts existed.
        let store = ReadingStore(folder: temporaryFolder())
        try FileManager.default.createDirectory(at: store.folder, withIntermediateDirectories: true)
        let old = #"{"l":"five_hour","p":"claude","r":1800000000,"t":1799990000,"u":12,"w":300}"#
        try Data((old + "\n").utf8).write(to: store.folder.appending(path: "claude-2027-01.jsonl"))
        let loaded = try #require(store.load(since: .distantPast).first)
        #expect(loaded.account == nil)
        #expect(loaded.key.id == "claude/five_hour")
        // The same reading saved today is written exactly as it was before.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        #expect(String(bytes: try encoder.encode(loaded), encoding: .utf8) == old)
    }

    @Test func savedListsRoundTrip() throws {
        let defaults = temporaryDefaults()
        var list = AccountList.load(from: defaults, environment: [:], home: home)
        let work = Account.make(.claude, folder: "~/.claude-work", home: home)
        list.add(work)
        list.rename(work, to: "  Client work  ")
        list.save(to: defaults)
        let loaded = AccountList.load(from: defaults, environment: ["CLAUDE_CONFIG_DIR": "/elsewhere"], home: home)
        #expect(loaded == list)
        #expect(loaded.account(.claude, slug: work.slug)?.name == "Client work")
        #expect(loaded.label(provider: .claude, slug: nil) == "Main")
        #expect(loaded.label(provider: .codex, slug: nil) == nil)
        var removed = loaded
        removed.remove(try #require(loaded.defaultAccount(.claude)))
        #expect(removed == loaded)
        removed.remove(work)
        #expect(removed.accounts(for: .claude).count == 1)
    }

    @Test func theConfigFolderVariablePicksTheAccount() {
        var list = AccountList.load(from: temporaryDefaults(), environment: [:], home: home)
        let work = Account.make(.claude, folder: "~/.claude-work", home: home)
        list.add(work)
        #expect(list.account(.claude, environment: [:], home: home)?.slug == nil)
        #expect(list.account(.claude, environment: ["CLAUDE_CONFIG_DIR": ""], home: home)?.slug == nil)
        #expect(list.account(.claude, environment: ["CLAUDE_CONFIG_DIR": "~/.claude"], home: home)?.slug == nil)
        #expect(list.account(.claude, environment: ["CLAUDE_CONFIG_DIR": home.path + "/.claude-work/"],
                             home: home)?.slug == work.slug)
        // A folder nobody added yet still gets its own slug, so its readings don't land on another account.
        let other = list.account(.claude, environment: ["CLAUDE_CONFIG_DIR": "~/.claude-other"], home: home)
        #expect(other?.slug == Account.make(.claude, folder: "~/.claude-other", home: home).slug)
        #expect(list.account(.codex, environment: ["CLAUDE_CONFIG_DIR": "~/.claude-work"], home: home)?.slug == nil)
    }

    @Test func findsOtherAccountFoldersWithAccountData() throws {
        _ = try folder(".claude", with: "settings.json")
        _ = try folder(".claude-work", with: ".claude.json")
        _ = try folder(".claude_client", with: "settings.json")
        _ = try folder(".claude-worktrees", with: "settings.json")
        _ = try folder(".claude-empty", with: nil)
        _ = try folder(".codex-work", with: "auth.json")
        _ = try folder(".codexy", with: "auth.json")
        try Data("{}".utf8).write(to: home.appending(path: ".claude.json"))
        var list = AccountList.load(from: temporaryDefaults(), environment: [:], home: home)
        #expect(list.candidates(home: home).map(\.name) == ["Work", "Client", "Work"])
        #expect(list.candidates(home: home).map(\.provider) == [.claude, .claude, .codex])
        list.add(list.candidates(home: home)[0])
        #expect(list.candidates(home: home).map(\.name) == ["Client", "Work"])
    }

    @Test func readsWhoIsSignedInWithoutCredentials() throws {
        let path = try folder(".claude-work", with: nil)
        let config: [String: Any] = ["oauthAccount": ["emailAddress": "ann@example.com",
                                                      "organizationName": "ann@example.com's Organization",
                                                      "planDisplayName": "Max"],
                                     "primaryApiKey": "secret"]
        let url = URL(filePath: path).appending(path: ".claude.json")
        try JSONSerialization.data(withJSONObject: config).write(to: url)
        let work = Account.make(.claude, folder: path, home: home)
        #expect(work.signedInAs(home: home, environment: [:]) == "ann@example.com · Max")
        let team = ["oauthAccount": ["emailAddress": "ann@acme.com", "organizationName": "Acme"]]
        try JSONSerialization.data(withJSONObject: team).write(to: home.appending(path: ".claude.json"))
        let main = Account.defaultAccount(.claude, environment: [:], home: home)
        #expect(main.signedInAs(home: home, environment: [:]) == "ann@acme.com · Acme")
        #expect(Account.make(.codex, folder: path, home: home).signedInAs(home: home, environment: [:]) == nil)
    }

    @Test func resetsArePerAccount() {
        let defaults = temporaryDefaults()
        let work = Account.make(.claude, folder: "~/.claude-work", home: home)
        ClaudeResets(weekly: .init(available: 4), recordedAt: Date(timeIntervalSince1970: 1_800_000_000))
            .save(to: defaults, account: work)
        #expect(ClaudeResets.load(from: defaults, account: work).weekly.available == 4)
        #expect(ClaudeResets.load(from: defaults).recordedAt == nil)
        #expect(defaults.integer(forKey: "claudeResetCount.\(work.slug!)") == 4)
    }
}
