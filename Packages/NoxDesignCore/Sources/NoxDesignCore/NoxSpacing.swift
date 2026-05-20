import Foundation
import NoxCore
import CoreGraphics

/// 4pt base scale — no arbitrary spacing in feature UI.
nonisolated public enum NoxSpacing {
    public static let unit: CGFloat = 4

    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let section: CGFloat = 48

    public static let menuBarWidth: CGFloat = 280

    /// Default vertical rhythm inside a surface page.
    public static let pageStack: CGFloat = lg

    /// Gap between cards inside a section.
    public static let cardStack: CGFloat = md

    /// Inner padding for standard cards.
    public static let cardInset: CGFloat = md

    /// Inner padding for hero / reflection cards.
    public static let cardInsetLoose: CGFloat = lg
}

public enum NoxSurfaceLayout {
    public static let contentMaxReadable: CGFloat = 520
    public static let gridMinCell: CGFloat = 200

    /// Semantic arc / pattern cards in a grid share this minimum height.
    public static let arcCardMinHeight: CGFloat = 96

    /// Each timeline fragment reserves title + two metadata lines.
    public static let timelineFragmentMinHeight: CGFloat = 56
    public static let timelineMetadataLineHeight: CGFloat = 16
}

public enum NoxTimelineMarkerLayout {
    public static let railWidth: CGFloat = 12
    public static let dotDiameter: CGFloat = 5
    public static let rowVerticalPadding: CGFloat = NoxSpacing.sm
    public static let titleLineHeight: CGFloat = 16

    public static var dotCenterY: CGFloat {
        rowVerticalPadding + titleLineHeight / 2
    }

    public static var rowHeight: CGFloat {
        rowVerticalPadding * 2 + NoxSurfaceLayout.timelineFragmentMinHeight
    }
}
