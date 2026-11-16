import PanelKit
import SwiftUI

/// The PanelKit theme for the current appearance, for the few panel pieces PanelKit doesn't have yet.
@propertyWrapper
struct BrushedTheme: DynamicProperty {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.panelThemeOverride) private var override

    var wrappedValue: PanelTheme {
        override ?? PanelTheme.resolve(colorScheme)
    }
}

/// A PanelKit-style tape with a faint extension to where usage is headed by the reset. Graphite unless the
/// window runs short.
struct ProjectedTape: View {
    /// Percent used, 0 to 100.
    let used: Double
    /// Percent projected at the reset, if there's a forecast.
    let projected: Double?
    let status: PanelStatus?
    @BrushedTheme private var theme

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Rectangle().fill(theme.track)
                if let projected, projected > used {
                    Rectangle().fill(fill.opacity(0.3))
                        .frame(width: width * min(projected, 100) / 100)
                }
                Rectangle().fill(fill)
                    .frame(width: width * min(max(used, 0), 100) / 100)
            }
        }
        .frame(height: 5)
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .accessibilityElement()
        .accessibilityLabel("Used")
        .accessibilityValue(projected.map { "\(Int(used.rounded())) percent, headed for \(Int(min($0, 100).rounded())) "
            + "percent by the reset" } ?? "\(Int(used.rounded())) percent")
    }

    private var fill: Color {
        switch status {
        case .caution: theme.caution
        case .stop: theme.stop
        default: theme.fill
        }
    }
}

/// A readout row like PanelKit's `Row`, except the lines under the name wrap instead of truncating, so long
/// forecast and reset lines stay whole.
struct InfoRow<Accessory: View>: View {
    let name: String
    var lines: [String] = []
    var value: String?
    var secondary: String?
    @ViewBuilder var accessory: () -> Accessory
    @BrushedTheme private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(PanelFont.body(13, .semibold))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(PanelFont.body(11.5))
                        .foregroundStyle(theme.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 4) {
                accessory()
                if let value {
                    Text(value)
                        .font(PanelFont.body(13))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                }
                if let secondary {
                    Text(secondary)
                        .font(PanelFont.body(11))
                        .monospacedDigit()
                        .foregroundStyle(theme.sub)
                }
            }
            .lineLimit(1)
            .fixedSize()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
    }
}

extension InfoRow where Accessory == EmptyView {
    init(_ name: String, lines: [String] = [], value: String? = nil, secondary: String? = nil) {
        self.init(name: name, lines: lines, value: value, secondary: secondary) { EmptyView() }
    }
}

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
    @BrushedTheme private var theme
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
