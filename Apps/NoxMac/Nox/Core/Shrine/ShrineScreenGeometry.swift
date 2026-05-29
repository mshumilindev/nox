import AppKit
import NoxShrineCore

enum ShrineScreenGeometry {
    static func screenRect(_ rect: NSRect) -> NoxShrineScreenRect {
        NoxShrineScreenRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
    }

    static func point(_ point: CGPoint) -> NoxShrinePoint {
        NoxShrinePoint(x: point.x, y: point.y)
    }

    static func cgPoint(_ point: NoxShrinePoint) -> CGPoint {
        CGPoint(x: point.x, y: point.y)
    }

    static func panelSize(_ size: CGSize) -> NoxShrineSize {
        NoxShrineSize(width: size.width, height: size.height)
    }
}
