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
