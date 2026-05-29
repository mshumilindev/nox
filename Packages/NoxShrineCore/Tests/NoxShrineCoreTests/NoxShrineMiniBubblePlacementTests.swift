import Foundation
import Testing
@testable import NoxShrineCore

@Test func bottomRightOriginRespectsPadding() {
    let visible = NoxShrineScreenRect(x: 0, y: 100, width: 800, height: 600)
    let size = NoxShrineSize(width: 72, height: 72)
    let origin = NoxShrineMiniBubblePlacement.bottomRightOrigin(
        visibleFrame: visible,
        panelSize: size,
        padding: 16
    )
    #expect(origin.x == 712)
    #expect(origin.y == 116)
}

@Test func clampKeepsPanelInsideVisibleFrame() {
    let visible = NoxShrineScreenRect(x: 0, y: 0, width: 400, height: 300)
    let size = NoxShrineSize(width: 72, height: 72)
    let clamped = NoxShrineMiniBubblePlacement.clamp(
        origin: NoxShrinePoint(x: -50, y: 500),
        panelSize: size,
        visibleFrame: visible
    )
    #expect(clamped.x == 0)
    #expect(clamped.y == 228)
}

@Test func invalidSavedOriginFallsBackToBottomRight() {
    let visible = NoxShrineScreenRect(x: 0, y: 0, width: 500, height: 400)
    let size = NoxShrineSize(width: 72, height: 72)
    let resolved = NoxShrineMiniBubblePlacement.resolvedOrigin(
        savedOrigin: NoxShrinePoint(x: 900, y: 900),
        visibleFrame: visible,
        panelSize: size
    )
    let expected = NoxShrineMiniBubblePlacement.bottomRightOrigin(visibleFrame: visible, panelSize: size)
    #expect(resolved == expected)
}

@Test func displayKeyIsStableForSameFrame() {
    let frame = NoxShrineScreenRect(x: 100, y: 200, width: 1440, height: 900)
    #expect(
        NoxShrineMiniBubblePlacement.displayKey(screenFrame: frame)
            == NoxShrineMiniBubblePlacement.displayKey(screenFrame: frame)
    )
}
