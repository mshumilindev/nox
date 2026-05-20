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

      if let intervention = environment.connectorSnapshot.intervention {
        NoxConnectorInterventionBanner(intervention: intervention)
      } else if let nudge = environment.ambientUtilitySnapshot.primaryNudge {
        NoxContextualNudgeBanner(nudge: nudge)
      }

      NoxConnectorPressureCard(snapshot: environment.connectorSnapshot)

      NoxConnectorCadenceCard(
        patterns: environment.connectorSnapshot.cadencePatterns,
        transitions: environment.connectorSnapshot.transitions
      )
    }
  }
}
