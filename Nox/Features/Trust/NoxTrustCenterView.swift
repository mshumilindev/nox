import SwiftUI

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
