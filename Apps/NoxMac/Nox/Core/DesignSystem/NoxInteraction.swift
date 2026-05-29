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

/// macOS-native press feedback without shrinking the hit region.
struct NoxBorderlessPressStyle: ButtonStyle {
    var pressedOpacity: Double = 0.78
    var hover: NoxAmbientHoverStyle = .row
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .noxAmbientHover(hover, isSelected: isSelected)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NoxBorderlessPressStyle {
    static var noxBorderless: NoxBorderlessPressStyle { NoxBorderlessPressStyle() }

    static func noxBorderless(
        hover: NoxAmbientHoverStyle,
        isSelected: Bool = false
    ) -> NoxBorderlessPressStyle {
        NoxBorderlessPressStyle(hover: hover, isSelected: isSelected)
    }
}

extension View {
    /// Ambient hover for toggles, pickers, and other native controls.
    func noxInteractiveChrome(
        _ style: NoxAmbientHoverStyle = .row,
        isSelected: Bool = false
    ) -> some View {
        noxAmbientHover(style, isSelected: isSelected)
    }
}
