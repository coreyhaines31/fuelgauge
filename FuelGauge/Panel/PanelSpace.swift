import AppKit
import FuelGaugeCore
import Observation

/// How much height the panel has below the menu bar, on the screen the status item is on.
@MainActor @Observable
final class PanelSpace {
    var availableHeight: CGFloat

    init(availableHeight: CGFloat? = nil) {
        self.availableHeight = availableHeight ?? Self.height(on: NSScreen.main, buttonMinY: nil)
    }

    /// Measures from the status item's button, on its own screen rather than whichever screen has focus.
    func update(for button: NSStatusBarButton) {
        guard let window = button.window else { return }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        availableHeight = Self.height(on: window.screen ?? NSScreen.main, buttonMinY: frame.minY)
    }

    private static func height(on screen: NSScreen?, buttonMinY: CGFloat?) -> CGFloat {
        guard let visible = screen?.visibleFrame else { return 900 }
        return PanelLayout.availableHeight(buttonMinY: buttonMinY ?? visible.maxY, visibleMinY: visible.minY)
    }
}
