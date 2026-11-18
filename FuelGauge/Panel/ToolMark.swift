import FuelGaugeCore
import PanelKit
import SwiftUI

/// A tool's own one-colour mark, so its section is easy to spot. The files are the vendors' official assets,
/// unaltered; see docs/third-party-marks.md for where each came from and the terms it's used under.
struct ToolMark: View {
    let provider: Provider
    var size: CGFloat = 12

    var body: some View {
        if let asset = Self.asset(for: provider) {
            Image(asset.name)
                .resizable()
                .renderingMode(.template)
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * asset.scale, height: size * asset.scale)
                .frame(width: size, height: size)
                .accessibilityLabel(provider.name)
        }
    }

    /// `scale` evens out the marks' optical size: OpenAI's file keeps its prescribed clear space inside the
    /// canvas, and Grok Bot's has a small margin, so they're drawn larger and the empty margin overhangs the slot.
    private static func asset(for provider: Provider) -> (name: String, scale: CGFloat)? {
        switch provider {
        case .claude: ("ToolMarkClaude", 1)
        case .codex: ("ToolMarkCodex", 1.45)
        case .grokBot: ("ToolMarkGrokBot", 1.08)
        case .cursor: ("ToolMarkCursor", 1)
        default: nil
        }
    }
}

/// PanelKit's `SectionHeader` with the tool's mark before the name, and the account's name after it when the
/// tool has several.
struct ToolSectionHeader: View {
    let provider: Provider
    var accountName: String?

    @Environment(\.panelTheme) private var theme

    /// Cap height of the 10pt condensed label, so the mark centres on the capitals rather than the line box.
    private static let capHeight: CGFloat = 7

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            ToolMark(provider: provider)
                .foregroundStyle(theme.ink)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + Self.capHeight / 2 }
            Text(accountName.map { "\(provider.name) · \($0)" } ?? provider.name)
                .font(PanelFont.condensed(10, .semibold))
                .tracking(10 * 0.2)
                .textCase(.uppercase)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
        }
        .foregroundStyle(theme.sub)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .padding(.horizontal, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.line).frame(height: 1)
        }
    }
}
