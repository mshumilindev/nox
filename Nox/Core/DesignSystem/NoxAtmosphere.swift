import SwiftUI

/// Ambient canvas — layered graphite depth without motion or neon.
struct NoxAtmosphereBackground: View {
    var density: Double = 0.45

    var body: some View {
        ZStack {
            NoxDesignTokens.ColorRole.canvas

            LinearGradient(
                colors: [
                    NoxDesignTokens.ColorRole.surface.opacity(0.22),
                    NoxDesignTokens.ColorRole.canvas,
                    NoxDesignTokens.ColorRole.canvas.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    NoxDesignTokens.ColorRole.accent.opacity(0.045 + density * 0.025),
                    .clear
                ],
                center: .topLeading,
                startRadius: 4,
                endRadius: 460
            )

            RadialGradient(
                colors: [
                    NoxDesignTokens.ColorRole.continuityTint.opacity(0.035),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 8,
                endRadius: 400
            )

            RadialGradient(
                colors: [
                    .clear,
                    NoxDesignTokens.ColorRole.canvas.opacity(0.55)
                ],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
        }
    }
}
