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

struct NoxMemoryDeepSpaceSection: View {
    let ownership: NoxMemoryEcologyOwnership
    let period: NoxMemoryPeriod
    let timelineSections: [NoxTimelineSection]
    let archivalEntries: [NoxMemoryDeepSpaceEntry]
    let isDeepReflection: Bool
    var activeTimelineSections: [NoxTimelineSection] = []
    var dayOverview: String?
    var eraObservation: String?
    var emergence: NoxMemoryEmergence?

    private var mergedActiveTimeline: [NoxTimelineSection] {
        if ownership.ecologyIsSeparated {
            return timelineSections
        }
        if period == .today, !activeTimelineSections.isEmpty {
            return activeTimelineSections
        }
        return timelineSections
    }

    private var timelineEmpty: Bool {
        mergedActiveTimeline.allSatisfy { $0.items.isEmpty }
    }

    private var isEmpty: Bool {
        timelineEmpty && archivalEntries.isEmpty
    }

    private var isPrimaryLayer: Bool {
        ownership.primaryLayer == .deepSpace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxMemoryEcologySectionHeader(
                title: NoxMemoryEcologyOwnershipResolver.deepSpaceName,
                subtitle: ownership.deepSpaceSectionSubtitle,
                weight: .deepSpace,
                isPrimaryLayer: isPrimaryLayer
            )

            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                if let residency = ownership.deepSpaceResidencyLine, !residency.isEmpty {
                    Text(residency)
                        .font(.system(size: 12))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
                }

                if let note = ownership.externalLayerNote, ownership.deviceRole == .station {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.58))
                }

                if ownership.ecologyIsSeparated {
                    Text(NoxMemoryEcologyCopy.deepSpacePeriodHint(period: period))
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
                }

                if let eraObservation, !eraObservation.isEmpty, !ownership.ecologyIsSeparated {
                    NoxMemoryEraObservationView(line: eraObservation)
                }

                if let dayOverview, !dayOverview.isEmpty, !ownership.ecologyIsSeparated {
                    Text(dayOverview)
                        .font(NoxTypography.body)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isEmpty, let emergence {
                    emergenceBlock(emergence)
                } else {
                    if !timelineEmpty {
                        VStack(alignment: .leading, spacing: isDeepReflection ? NoxSpacing.lg : NoxSpacing.md) {
                            ForEach(mergedActiveTimeline) { section in
                                NoxTimelineSectionView(section: section)
                            }
                        }
                    } else if let emergence, period == .today, !ownership.ecologyIsSeparated {
                        emergenceBlock(emergence)
                    }

                    if !archivalEntries.isEmpty {
                        if !timelineEmpty {
                            Text(NoxMemoryEcologyCopy.deepSpacePeriodHint(period: .today))
                                .font(NoxTypography.caption)
                                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
                                .padding(.top, NoxSpacing.xs)
                        }
                        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                            ForEach(archivalEntries) { entry in
                                archivalRow(entry)
                            }
                        }
                    }
                }

                if timelineEmpty && archivalEntries.isEmpty && emergence == nil {
                    Text(NoxMemoryEcologyCopy.deepSpaceEmpty)
                        .font(NoxTypography.body)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.72))
                }
            }
            .opacity(
                isPrimaryLayer && !ownership.ecologyIsSeparated
                    ? NoxMemoryEcologyLayerVisualWeight.galaxy.contentOpacity
                    : NoxMemoryEcologyLayerVisualWeight.deepSpace.contentOpacity
            )
            .noxSurface(isPrimaryLayer && !ownership.ecologyIsSeparated ? .standard : .inset, padding: NoxSpacing.lg)
        }
    }

    private func emergenceBlock(_ emergence: NoxMemoryEmergence) -> some View {
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

    private func archivalRow(_ entry: NoxMemoryDeepSpaceEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.title)
                .font(.system(size: 13))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            if let detail = entry.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.55))
            }
        }
        .padding(.vertical, NoxSpacing.xxs)
    }
}
