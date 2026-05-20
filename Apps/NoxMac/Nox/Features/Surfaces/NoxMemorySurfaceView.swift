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

struct NoxMemorySurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NoxSurfacePage {
            NoxMemoryPeriodPicker()
            NoxMemorySearchField()

            if let overview = environment.daySemanticOverview, environment.memoryPeriod == .today {
                Text(overview)
                    .font(NoxTypography.body)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
            }

            NoxMemoryTimelineView(
                period: environment.memoryPeriod,
                sections: environment.timelineSections,
                stats: environment.dayStats,
                emergence: environment.memoryEmergence,
                density: environment.memoryDensity,
                dayOverview: nil,
                presence: environment.presence,
                eraObservation: NoxTemporalMemoryRowPresenter.eraObservation(
                    for: environment.memoryEvolutionSnapshot
                )
            )
        }
    }
}
