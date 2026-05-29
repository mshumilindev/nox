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

struct NoxTrustCenterView: View {
  var body: some View {
    NoxSurfacePage {
      NoxPageIntro(
        title: "Trust",
        subtitle: "What stays on this Mac, and what Nox never records."
      )

      NoxTrustBoundariesList()

      NoxSensitiveContextExplanation()

      NoxConnectorTrustControls()

      NoxAmbientUtilityTrustControls()
      NoxSystemStateTrustControls()

      NoxMemoryControlCenter()
    }
  }
}
