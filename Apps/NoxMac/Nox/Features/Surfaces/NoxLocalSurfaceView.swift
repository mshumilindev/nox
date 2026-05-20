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

struct NoxLocalSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NoxSurfacePage {
            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                NoxLocalFirstBadge()
                localTable
            }
            .noxSurface(.soft, padding: NoxSpacing.lg)

            NoxAwarenessCard(snapshot: environment.awarenessSnapshot)

            NoxCollapsibleSection(title: "Awareness levels", defaultExpanded: false) {
                NoxCapabilityExplanationView(
                    level: environment.awarenessSnapshot.level,
                    capabilities: environment.capabilities
                )
            }

            NoxSystemStatusView()
        }
    }

    private var localTable: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            localLine("Runs locally on this Mac")
            localLine("Stored on this Mac · No cloud processing")
            localLine("No screenshots · No clipboard · No keystroke recording")
        }
    }

    private func localLine(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
            Circle()
                .fill(NoxDesignTokens.ColorRole.accent.opacity(0.45))
                .frame(width: 4, height: 4)
            Text(text)
                .noxMetadata()
        }
    }
}
