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

struct NoxHeartbeatTriskelionView: View {
    let size: CGFloat
    let isActive: Bool

    @State private var beat = false

    var body: some View {
        Image("NoxTriskelionMark")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(isActive ? 0.98 : 0.94))
            .frame(width: size, height: size)
            .scaleEffect(isActive && beat ? 1.12 : 0.94)
            .opacity(isActive && beat ? 1.0 : 0.82)
            .shadow(
                color: NoxDesignTokens.ColorRole.accent.opacity(isActive && beat ? 0.45 : 0.18),
                radius: isActive && beat ? 18 : 8
            )
            .animation(
                isActive
                    ? .easeInOut(duration: 0.48).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.18),
                value: beat
            )
            .onAppear {
                beat = isActive
            }
            .onChange(of: isActive) { _, active in
                beat = active
            }
    }
}
