import SwiftUI

extension NoxPresenceListeningView {
    /// Subtle breathing glow for empty states.
    struct AuroraBreath: View {
        @State private var phase = false

        var body: some View {
            RadialGradient(
                colors: [
                    NoxDesignTokens.ColorRole.accent.opacity(phase ? 0.14 : 0.05),
                    .clear,
                ],
                center: .center,
                startRadius: 20,
                endRadius: phase ? 220 : 160
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                    phase = true
                }
            }
        }
    }
}

/// Namespace for empty-state helpers — listening UI lives in `NoxPresenceListeningOverlay`.
enum NoxPresenceListeningView {}
