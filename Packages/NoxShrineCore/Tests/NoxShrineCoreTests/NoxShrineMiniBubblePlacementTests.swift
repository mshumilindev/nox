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

@Test func notchDockingClampExtendsTopBeyondVisibleFrame() {
    let screen = NoxShrineScreenRect(x: 0, y: 0, width: 1440, height: 900)
    let visible = NoxShrineScreenRect(x: 0, y: 0, width: 1440, height: 876)
    let size = NoxShrineSize(width: 104, height: 104)
    let normal = NoxShrineMiniBubblePlacement.clamp(
        origin: NoxShrinePoint(x: 600, y: 820),
        panelSize: size,
        mode: .normalBubble,
        screenFrame: screen,
        visibleFrame: visible
    )
    let docking = NoxShrineMiniBubblePlacement.clamp(
        origin: NoxShrinePoint(x: 600, y: 820),
        panelSize: size,
        mode: .notchDocking,
        screenFrame: screen,
        visibleFrame: visible
    )
    #expect(normal.y == 772)
    #expect(docking.y == 820)
    #expect(docking.y > normal.y)
}

@Test func notchDockingClampCanPlaceOrbCenterOnAnchor() {
    let screen = NoxShrineScreenRect(x: 0, y: 0, width: 1440, height: 900)
    let visible = NoxShrineScreenRect(x: 0, y: 0, width: 1440, height: 876)
    let size = NoxShrineSize(width: 156, height: 156)
    let anchorY: CGFloat = 885
    let docking = NoxShrineMiniBubblePlacement.clamp(
        origin: NoxShrinePoint(x: 600, y: anchorY - size.height / 2),
        panelSize: size,
        mode: .notchDocking,
        screenFrame: screen,
        visibleFrame: visible,
        notchAnchorY: anchorY
    )
    #expect(docking.y == anchorY - size.height / 2)
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
