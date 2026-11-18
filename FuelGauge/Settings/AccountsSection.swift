import AppKit
import FuelGaugeCore
import SwiftUI

/// A tool's accounts in Settings › Tools: one row per config folder, with its name, who's signed in, and (for
/// Claude Code) its status line; folders that look like more accounts; and "Add Folder…".
struct AccountsSection: View {
    let provider: Provider
    let model: UsageModel
    /// Who's signed in, by `Account.id`, and folders that look like more accounts; read off the main thread.
    let signedIn: [String: String]
    let candidates: [Account]
    /// Reads `signedIn` and `candidates` again after the list changes.
    let reload: () -> Void
    @State private var names: [String: String] = [:]
    @State private var message: String?

    var body: some View {
        Section {
            ForEach(model.accounts(for: provider)) { account in
                row(account)
            }
            ForEach(candidates.filter { $0.provider == provider }) { candidate in
                candidateRow(candidate)
            }
            HStack {
                Spacer()
                Button("Add Folder…", action: chooseFolder)
            }
        } header: {
            Text("\(provider.name) accounts")
        } footer: {
            Text(message ?? footer)
                .font(.caption).foregroundStyle(message == nil ? .secondary : Color.red)
        }
    }

    private var footer: String {
        let variable = Account.folderVariable(for: provider) ?? ""
        let example = provider == .codex ? "CODEX_HOME=~/.codex-work codex" : "CLAUDE_CONFIG_DIR=~/.claude-work claude"
        var text = "Each account is a config folder, like \(example). Fuel Gauge reads each one separately and "
            + "runs its checks with that folder's \(variable), so each uses its own sign-in."
        if provider == .claude {
            text += " Claude Code only shares its limits with a status line, so turn it on for each account. "
                + "Settings are backed up first, and an existing status line keeps showing above the forecast."
        }
        return text
    }

    private func row(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField("Name", text: Binding(
                    get: { names[account.id] ?? account.name },
                    set: { names[account.id] = $0 }
                ))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 160)
                .onSubmit { commitName(account) }
                Spacer()
                if provider == .claude {
                    statusLineButton(account)
                }
                if !account.isDefault {
                    Button("Remove") {
                        model.removeAccount(account)
                        reload()
                    }
                }
            }
            Text(detail(account))
                .font(.caption).foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
        .onDisappear { commitName(account) }
    }

    @ViewBuilder private func statusLineButton(_ account: Account) -> some View {
        switch model.claudeStatusLine(for: account) {
        case .on:
            Button("Status Line Off") { setStatusLine(false, account) }
        case .off, .otherCommand:
            Button("Status Line On") { setStatusLine(true, account) }
        }
    }

    /// "~/.claude-work · ann@example.com · Max · status line on".
    private func detail(_ account: Account) -> String {
        var parts = [Self.abbreviated(account.folderPath)]
        if let who = signedIn[account.id] { parts.append(who) }
        if account.isDefault, model.accounts(for: provider).count > 1 { parts.append("default") }
        if provider == .claude {
            parts.append(model.claudeStatusLine(for: account) == .on ? "status line on" : "status line off")
        }
        return parts.joined(separator: " · ")
    }

    private func candidateRow(_ candidate: Account) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Found \(Self.abbreviated(candidate.folderPath))")
                Text(signedIn[candidate.id] ?? "Looks like another \(provider.name) account")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Add") { add(candidate) }
        }
    }

    private func commitName(_ account: Account) {
        guard let name = names[account.id], name != account.name else { return }
        names[account.id] = nil
        model.renameAccount(account, to: name)
    }

    private func add(_ account: Account) {
        message = nil
        model.addAccount(account)
        reload()
    }

    private func setStatusLine(_ on: Bool, _ account: Account) {
        do {
            try model.setClaudeStatusLine(on: on, account: account)
            message = nil
        } catch {
            message = "Couldn't update \(account.name)'s Claude Code settings: \(error.localizedDescription)"
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.directoryURL = .homeDirectory
        panel.message = provider == .codex
            ? "Choose the folder an account's CODEX_HOME points at, like ~/.codex-work."
            : "Choose the folder an account's CLAUDE_CONFIG_DIR points at, like ~/.claude-work."
        panel.prompt = "Add Account"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let account = model.accounts.account(provider, folder: url.path)
        if model.accounts(for: provider).contains(where: { $0.folderPath == account.folderPath }) {
            message = "\(Self.abbreviated(account.folderPath)) is already tracked."
        } else if !account.hasAccountData {
            message = "\(Self.abbreviated(account.folderPath)) has no \(provider.name) sign-in, settings, or logs "
                + "yet. Sign in with that folder first, then add it."
        } else {
            add(account)
        }
    }

    static func abbreviated(_ path: String) -> String {
        let home = URL.homeDirectory.path
        return path == home || path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}
