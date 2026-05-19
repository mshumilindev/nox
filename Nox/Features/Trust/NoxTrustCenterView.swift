import SwiftUI

struct NoxTrustCenterView: View {
  var body: some View {
    NoxSurfacePage {
      NoxPageIntro(
        title: "Trust surface",
        subtitle: "What stays on this Mac — and what never enters memory."
      )

      NoxTrustBoundariesList()

      NoxSensitiveContextExplanation()

      NoxConnectorTrustControls()

      NoxMemoryControlCenter()
    }
  }
}
