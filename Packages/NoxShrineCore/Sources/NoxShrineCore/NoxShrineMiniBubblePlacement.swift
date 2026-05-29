import Foundation

/// Screen rectangle in AppKit-style coordinates (origin bottom-left).
public struct NoxShrineScreenRect: Equatable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: CGFloat { x }
    public var minY: CGFloat { y }
    public var maxX: CGFloat { x + width }
    public var maxY: CGFloat { y + height }

    public func contains(_ point: NoxShrinePoint, panelSize: NoxShrineSize, tolerance: CGFloat = 0) -> Bool {
        let frame = NoxShrineScreenRect(
            x: point.x,
            y: point.y,
            width: panelSize.width,
            height: panelSize.height
        )
        return frame.minX >= minX - tolerance
            && frame.minY >= minY - tolerance
            && frame.maxX <= maxX + tolerance
            && frame.maxY <= maxY + tolerance
    }
}

public struct NoxShrinePoint: Equatable, Sendable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

public struct NoxShrineSize: Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

/// Pure placement helpers for the Floating Mini Shrine Bubble (Foundation-only, testable).
public enum NoxShrineMiniBubblePlacement: Sendable {
    public static let defaultEdgePadding: CGFloat = 16
    public static let defaultPanelSize = NoxShrineSize(width: 72, height: 72)

    public static func displayKey(screenFrame: NoxShrineScreenRect) -> String {
        let f = screenFrame
        return "\(Int(f.minX)):\(Int(f.minY)):\(Int(f.width)):\(Int(f.height))"
    }

    public static func bottomRightOrigin(
        visibleFrame: NoxShrineScreenRect,
        panelSize: NoxShrineSize = defaultPanelSize,
        padding: CGFloat = defaultEdgePadding
    ) -> NoxShrinePoint {
        NoxShrinePoint(
            x: visibleFrame.maxX - panelSize.width - padding,
            y: visibleFrame.minY + padding
        )
    }

    public static func clamp(
        origin: NoxShrinePoint,
        panelSize: NoxShrineSize,
        visibleFrame: NoxShrineScreenRect
    ) -> NoxShrinePoint {
        NoxShrinePoint(
            x: min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - panelSize.width),
            y: min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - panelSize.height)
        )
    }

    public static func isFullyVisible(
        origin: NoxShrinePoint,
        panelSize: NoxShrineSize,
        visibleFrame: NoxShrineScreenRect,
        tolerance: CGFloat = 4
    ) -> Bool {
        visibleFrame.contains(origin, panelSize: panelSize, tolerance: tolerance)
    }

    public static func resolvedOrigin(
        savedOrigin: NoxShrinePoint?,
        visibleFrame: NoxShrineScreenRect,
        panelSize: NoxShrineSize = defaultPanelSize,
        padding: CGFloat = defaultEdgePadding
    ) -> NoxShrinePoint {
        guard let savedOrigin,
              isFullyVisible(origin: savedOrigin, panelSize: panelSize, visibleFrame: visibleFrame) else {
            return bottomRightOrigin(visibleFrame: visibleFrame, panelSize: panelSize, padding: padding)
        }
        return clamp(origin: savedOrigin, panelSize: panelSize, visibleFrame: visibleFrame)
    }
}
