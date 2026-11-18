import Foundation

/// Sizes the panel so it always fits below the menu bar: the cards scroll, and everything around them (the
/// fascia, the verdict, the links, the footer) stays in view.
public enum PanelLayout {
    /// The shortest the cards area gets, however little room the screen has.
    public static let minimumCardsHeight: Double = 160
    /// Room kept free below the status item for the popover's arrow and a gap above the Dock or screen edge.
    public static let popoverMargin: Double = 28

    /// The height a popover can use below a status item: from the bottom of its button down to the bottom of the
    /// screen's visible frame (above the Dock), less the arrow and a gap. Both values are in screen coordinates.
    public static func availableHeight(buttonMinY: Double, visibleMinY: Double) -> Double {
        max(0, buttonMinY - visibleMinY - popoverMargin)
    }

    /// The cards area's height: as tall as its content, but no taller than the room `available` leaves once the
    /// parts outside the scroll area (`chrome`) are drawn, and never shorter than `minimumCardsHeight`.
    public static func cardsHeight(content: Double, available: Double, chrome: Double) -> Double {
        min(content, max(minimumCardsHeight, available - chrome))
    }
}
