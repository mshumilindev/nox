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
    /// Small inset from the physical top edge while docking toward the notch.
    public static let notchDockingTopMargin: CGFloat = 6

    /// Normal bubble drag uses `visibleFrame`. Notch docking drag extends the top toward `screenFrame.maxY`.
    public enum ClampMode: Sendable {
        case normalBubble
        case notchDocking
    }

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
        clamp(
            origin: origin,
            panelSize: panelSize,
            mode: .normalBubble,
            screenFrame: visibleFrame,
            visibleFrame: visibleFrame
        )
    }

    /// Returns the clamp rect for the given mode. Notch docking uses the physical screen frame so
    /// the bubble center can enter the menu-bar/notch band during an active docking drag.
    public static func clampFrame(
        mode: ClampMode,
        screenFrame: NoxShrineScreenRect,
        visibleFrame: NoxShrineScreenRect,
        topMargin: CGFloat = notchDockingTopMargin
    ) -> NoxShrineScreenRect {
        switch mode {
        case .normalBubble:
            return visibleFrame
        case .notchDocking:
            let horizontalInset: CGFloat = 4
            return NoxShrineScreenRect(
                x: screenFrame.minX + horizontalInset,
                y: screenFrame.minY,
                width: max(0, screenFrame.width - horizontalInset * 2),
                height: screenFrame.height
            )
        }
    }

    public static func clamp(
        origin: NoxShrinePoint,
        panelSize: NoxShrineSize,
        mode: ClampMode,
        screenFrame: NoxShrineScreenRect,
        visibleFrame: NoxShrineScreenRect,
        topMargin: CGFloat = notchDockingTopMargin,
        notchAnchorY: CGFloat? = nil
    ) -> NoxShrinePoint {
        let frame = clampFrame(
            mode: mode,
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            topMargin: topMargin
        )

        if mode == .notchDocking {
            let centerMargin = max(CGFloat(4), min(panelSize.width, panelSize.height) * 0.08)
            let proposedCenter = NoxShrinePoint(
                x: origin.x + panelSize.width / 2,
                y: origin.y + panelSize.height / 2
            )
            let maxCenterY = notchAnchorY.map { max(frame.maxY - centerMargin, $0) }
                ?? (frame.maxY - centerMargin)
            let clampedCenterX = min(
                max(proposedCenter.x, frame.minX + centerMargin),
                frame.maxX - centerMargin
            )
            let clampedCenterY = min(
                max(proposedCenter.y, frame.minY + centerMargin),
                maxCenterY
            )
            return NoxShrinePoint(
                x: clampedCenterX - panelSize.width / 2,
                y: clampedCenterY - panelSize.height / 2
            )
        }

        return NoxShrinePoint(
            x: min(max(origin.x, frame.minX), frame.maxX - panelSize.width),
            y: min(max(origin.y, frame.minY), frame.maxY - panelSize.height)
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
