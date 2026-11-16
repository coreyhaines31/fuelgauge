import PanelKit
import SwiftUI

/// A row of text links, as in the mockup's link bar.
struct LinkBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 14) {
            Group { content() }
                .fixedSize()
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
        .buttonStyle(.plain)
        .font(PanelFont.body(12))
        .foregroundStyle(Color(nsColor: .linkColor))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

/// A small metal key for actions inside a row, such as Refresh.
struct SmallKeyStyle: ButtonStyle {
    @Environment(\.panelTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PanelFont.body(11.5, .semibold))
            .lineLimit(1)
            .foregroundStyle(theme.ink)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background {
                let shape = RoundedRectangle(cornerRadius: 4)
                shape.fill(LinearGradient(colors: theme.button2, startPoint: .top, endPoint: .bottom))
                    .overlay(shape.strokeBorder(theme.button2Edge, lineWidth: 1))
            }
            .opacity(configuration.isPressed ? 0.8 : (isEnabled ? 1 : 0.5))
            .contentShape(Rectangle())
    }
}
