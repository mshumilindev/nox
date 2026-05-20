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

struct NoxPresencePanel: View {
  let state: NoxPresenceState
  let sessionSummary: String?
  var semanticHint: String?
  var capabilities: NoxCapabilityState?
  var density: Double = 0.45

  @State private var breathe = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Presence")
        .noxSectionLabel()
        .padding(.bottom, NoxSpacing.sm)

      ZStack(alignment: .leading) {
        if state.shouldBreathe {
          RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
            .fill(
              NoxDesignTokens.ColorRole.accent.opacity(
                (breathe ? 0.05 : 0.02) * (0.7 + density * 0.3)
              )
            )
            .animation(
              .easeInOut(duration: NoxDesignTokens.Animation.breathe).repeatForever(autoreverses: true),
              value: breathe
            )
        }

        NoxPresenceBadgeView(
          state: state,
          sessionSummary: sessionSummary,
          semanticHint: semanticHint,
          capabilities: capabilities
        )
        .padding(NoxSpacing.md)
      }
    }
    .noxSurface(.standard)
    .onAppear { breathe = true }
  }
}
