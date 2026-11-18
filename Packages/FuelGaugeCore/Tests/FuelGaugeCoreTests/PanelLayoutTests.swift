import FuelGaugeCore
import Testing

@Test func shortCardsKeepTheirOwnHeight() {
    #expect(PanelLayout.cardsHeight(content: 300, available: 800, chrome: 380) == 300)
}

@Test func tallCardsScrollInTheRoomTheChromeLeaves() {
    for available in [700.0, 800, 1000] {
        let cards = PanelLayout.cardsHeight(content: 1500, available: available, chrome: 380)
        #expect(cards == available - 380)
        #expect(cards + 380 <= available)
    }
}

@Test func aWrappedVerdictShrinksTheCardsArea() {
    let oneLine = PanelLayout.cardsHeight(content: 1500, available: 800, chrome: 380)
    let threeLines = PanelLayout.cardsHeight(content: 1500, available: 800, chrome: 380 + 2 * 26)
    #expect(threeLines == oneLine - 52)
}

@Test func theCardsAreaNeverGetsShorterThanTheMinimum() {
    #expect(PanelLayout.cardsHeight(content: 1500, available: 400, chrome: 380) == PanelLayout.minimumCardsHeight)
    #expect(PanelLayout.cardsHeight(content: 100, available: 400, chrome: 380) == 100)
}

@Test func availableHeightRunsFromTheButtonToTheBottomOfTheVisibleFrame() {
    // A 1000pt-tall visible frame starting above an 80pt Dock, with the button's bottom at the menu bar's edge.
    #expect(PanelLayout.availableHeight(buttonMinY: 1080, visibleMinY: 80) == 1000 - PanelLayout.popoverMargin)
    #expect(PanelLayout.availableHeight(buttonMinY: 10, visibleMinY: 80) == 0)
}
