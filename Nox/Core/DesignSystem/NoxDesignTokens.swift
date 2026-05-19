import SwiftUI

enum NoxDesignTokens {
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
    }

    enum Opacity {
        static let disabled: Double = 0.42
        static let subtle: Double = 0.55
        static let secondary: Double = 0.72
        static let divider: Double = 0.35
    }

    enum SymbolSize {
        static let sm: CGFloat = 11
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let brand: CGFloat = 16
    }

    enum Window {
        static let width: CGFloat = 480
        static let height: CGFloat = 600
        static let minWidth: CGFloat = 440
        static let maxWidth: CGFloat = 520
        static let minHeight: CGFloat = 520
        static let maxHeight: CGFloat = 700
    }

    enum Animation {
        static let panelReveal: TimeInterval = 0.22
        static let breathe: TimeInterval = 3.6
        static let pulse: TimeInterval = 2.4
    }

    enum Shadow {
        static let menuBarOpacity: Double = 0.10
        static let menuBarRadius: CGFloat = 10
        static let menuBarYOffset: CGFloat = 3
    }

    enum Icon {
        static let menuBarSymbol = "moon.stars.fill"
        static let brandSymbol = "moon.stars"
    }

    enum ColorRole {
        static var accent: Color { Color("NoxAccent") }
        static var surface: Color { Color("NoxSurface") }
        static var surfaceElevated: Color { Color("NoxSurfaceElevated") }
        static var border: Color { Color("NoxBorder") }
        static var textPrimary: Color { Color("NoxTextPrimary") }
        static var textSecondary: Color { Color("NoxTextSecondary") }
        static var presenceActive: Color { Color("NoxPresenceActive") }
        static var presenceMuted: Color { Color("NoxPresenceResting") }
    }
}
