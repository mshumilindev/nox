import AppKit
import SwiftUI

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
            .noxPointerCursor()
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
    /// Pointing-hand cursor — use only on discrete interactive controls, not labels or rows.
    func noxPointerCursor(_ enabled: Bool = true) -> some View {
        modifier(NoxPointerCursorModifier(enabled: enabled))
    }

    /// Hover + pointer for toggles, pickers, and other native controls.
    func noxInteractiveChrome(
        _ style: NoxAmbientHoverStyle = .row,
        isSelected: Bool = false
    ) -> some View {
        noxAmbientHover(style, isSelected: isSelected)
            .noxPointerCursor()
    }
}

private struct NoxPointerCursorModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                guard enabled else { return }
                switch phase {
                case .active:
                    NSCursor.pointingHand.push()
                case .ended:
                    NSCursor.pop()
                }
            }
    }
}
