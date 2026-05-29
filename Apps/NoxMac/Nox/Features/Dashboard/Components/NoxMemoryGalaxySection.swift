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

struct NoxMemoryGalaxySection: View {
    let ownership: NoxMemoryEcologyOwnership
    let sections: [NoxTimelineSection]
    let emergence: NoxMemoryEmergence
    let dayOverview: String?
    let eraObservation: String?
    let isDeepReflection: Bool

    private var isEmpty: Bool {
        sections.allSatisfy { $0.items.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxMemoryEcologySectionHeader(
                title: NoxMemoryEcologyOwnershipResolver.galaxyName,
                subtitle: ownership.galaxySectionSubtitle,
                weight: .galaxy,
                isPrimaryLayer: ownership.primaryLayer == .galaxy
            )

            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                if let eraObservation, !eraObservation.isEmpty {
                    NoxMemoryEraObservationView(line: eraObservation)
                }

                if let dayOverview, !dayOverview.isEmpty {
                    Text(dayOverview)
                        .font(NoxTypography.body)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isEmpty {
                    emergenceState
                } else {
                    VStack(alignment: .leading, spacing: isDeepReflection ? NoxSpacing.xl : NoxSpacing.lg) {
                        ForEach(sections) { section in
                            NoxTimelineSectionView(section: section)
                        }
                    }
                }
            }
            .opacity(NoxMemoryEcologyLayerVisualWeight.galaxy.contentOpacity)
            .noxSurface(.standard, padding: NoxSpacing.lg)
        }
    }

    private var emergenceState: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(emergence.title)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            if !emergence.detail.isEmpty {
                Text(emergence.detail)
                    .noxMetadata()
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let windowLine = emergence.observationWindowLine {
                Text(windowLine)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.55))
            }
        }
    }
}
