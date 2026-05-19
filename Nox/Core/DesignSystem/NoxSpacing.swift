import CoreGraphics

/// 4pt base scale — no arbitrary spacing in feature UI.
enum NoxSpacing {
    static let unit: CGFloat = 4

    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let section: CGFloat = 48

    static let menuBarWidth: CGFloat = 280

    /// Default vertical rhythm inside a surface page.
    static let pageStack: CGFloat = lg

    /// Gap between cards inside a section.
    static let cardStack: CGFloat = md

    /// Inner padding for standard cards.
    static let cardInset: CGFloat = md

    /// Inner padding for hero / reflection cards.
    static let cardInsetLoose: CGFloat = lg
}

enum NoxSurfaceLayout {
    static let contentMaxReadable: CGFloat = 520
    static let gridMinCell: CGFloat = 200

    /// Semantic arc / pattern cards in a grid share this minimum height.
    static let arcCardMinHeight: CGFloat = 96

    /// Each timeline fragment reserves title + two metadata lines.
    static let timelineFragmentMinHeight: CGFloat = 56
    static let timelineMetadataLineHeight: CGFloat = 16
}
