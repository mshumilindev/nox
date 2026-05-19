import SwiftUI

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
                blocks: environment.timelineBlocks,
                emergence: environment.memoryEmergence,
                density: environment.memoryDensity,
                dayOverview: nil,
                presence: environment.presence
            )
        }
    }
}
