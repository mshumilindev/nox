import SwiftUI
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore

nonisolated enum NoxDesignTokens {
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
    }

    enum Opacity {
        static let disabled: Double = 0.4
        static let subtle: Double = 0.9
        static let secondary: Double = 0.78
        static let divider: Double = 0.32
        static let selectionFill: Double = 0.1
        static let selectionStroke: Double = 0.18
    }

    enum SymbolSize {
        static let section: CGFloat = 11
        static let inline: CGFloat = 12
        static let chrome: CGFloat = 13
        static let rail: CGFloat = 14
        static let sm: CGFloat = 11
        static let md: CGFloat = 13
        static let lg: CGFloat = 15
        static let brand: CGFloat = 14
    }

    enum Window {
        static let width: CGFloat = expandedWidth
        static let height: CGFloat = expandedHeight

        static let compactWidth: CGFloat = 368
        static let compactHeight: CGFloat = 460
        static let expandedWidth: CGFloat = 560
        static let expandedHeight: CGFloat = 660
        static let deepWidth: CGFloat = 720
        static let deepHeight: CGFloat = 820

        static let minWidth: CGFloat = 340
        static let maxWidth: CGFloat = 760
        static let minHeight: CGFloat = 420
        static let maxHeight: CGFloat = 860
    }

    enum Animation {
        static let panelReveal: TimeInterval = 0.28
        static let surfaceFade: TimeInterval = 0.22
        static let breathe: TimeInterval = 4.2
        static let pulse: TimeInterval = 2.8
    }

    enum Shadow {
        static let shellOpacity: Double = 0.28
        static let shellRadius: CGFloat = 20
        static let shellYOffset: CGFloat = 6
        static let menuBarOpacity: Double = 0.08
        static let menuBarRadius: CGFloat = 8
        static let menuBarYOffset: CGFloat = 2
    }

    enum Icon {
        static let brandAsset = "NoxTriskelionMark"
    }

    enum ColorRole {
        static var canvas: Color { Color("NoxCanvas") }
        static var rail: Color { Color("NoxRail") }
        static var accent: Color { Color("NoxAccent") }
        static var surface: Color { Color("NoxSurface") }
        static var surfaceElevated: Color { Color("NoxSurfaceElevated") }
        static var border: Color { Color("NoxBorder") }
        static var textPrimary: Color { Color("NoxTextPrimary") }
        static var textSecondary: Color { Color("NoxTextSecondary") }
        static var presenceActive: Color { Color("NoxPresenceActive") }
        static var presenceMuted: Color { Color("NoxPresenceResting") }
        static var reflectionFill: Color { Color("NoxReflectionFill") }
        static var reflectionStroke: Color { Color("NoxReflectionStroke") }
        static var trustFill: Color { Color("NoxTrustFill") }
        static var continuityTint: Color { Color("NoxContinuityTint") }
    }
}
