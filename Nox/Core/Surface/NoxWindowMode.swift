import Foundation
import CoreGraphics

enum NoxWindowMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case compact
    case expanded
    case deepReflection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Compact"
        case .expanded: "Expanded"
        case .deepReflection: "Deep reflection"
        }
    }

    var size: (width: CGFloat, height: CGFloat) {
        switch self {
        case .compact:
            (NoxDesignTokens.Window.compactWidth, NoxDesignTokens.Window.compactHeight)
        case .expanded:
            (NoxDesignTokens.Window.expandedWidth, NoxDesignTokens.Window.expandedHeight)
        case .deepReflection:
            (NoxDesignTokens.Window.deepWidth, NoxDesignTokens.Window.deepHeight)
        }
    }
}

enum NoxSurfaceDensity: String, CaseIterable, Codable, Sendable {
    case calm
    case balanced
    case rich

    var sectionSpacing: CGFloat {
        switch self {
        case .calm: NoxSpacing.lg
        case .balanced: NoxSpacing.md
        case .rich: NoxSpacing.sm
        }
    }

    var showsDetailByDefault: Bool {
        self == .rich
    }
}
