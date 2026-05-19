import SwiftUI

struct NoxNowSurfaceView: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    NoxSurfacePage {
      NoxDashboardHeader(presence: environment.presence)

      NoxAwarenessCard(snapshot: environment.awarenessSnapshot)

      if let reason = environment.primaryExplanation {
        NoxContextExplanationCard(reason: reason)
      }

      NoxPresencePanel(
        state: environment.presence,
        sessionSummary: environment.sessionSummary,
        semanticHint: environment.semanticHint,
        capabilities: environment.capabilities,
        density: environment.memoryDensity
      )

      if !environment.liveSignals.isEmpty {
        NoxLiveSignalsView(signals: environment.liveSignals)
      }

      if let morning = environment.morningSummary, !morning.isEmpty {
        NoxMorningSummaryBanner(summary: morning)
      }
    }
  }
}
