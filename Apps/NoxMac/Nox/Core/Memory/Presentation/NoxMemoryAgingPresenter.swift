import Foundation
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

nonisolated enum NoxMemoryAgingPresenter {

    struct Input: Sendable {
        let subjectId: String
        let lastActiveAt: Date
        let recurrenceStrength: Double
        let continuityGravity: Double
        let temporalWeight: Double?
        let confidence: Double
        let isResumed: Bool
        let at: Date
    }

    static func temporalState(
        profile: NoxMemoryAgingProfile?,
        input: Input
    ) -> NoxMemoryTemporalState {
        if let profile {
            return NoxMemoryTemporalState.from(agingBand: profile.band)
        }
        let gap = input.at.timeIntervalSince(input.lastActiveAt)
        if input.isResumed, gap < 48 * 3600 { return .resurfacing }
        if gap < 6 * 3600 { return .active }
        if gap < 72 * 3600 { return .fading }
        if gap < 21 * 86_400 { return .dormant }
        return .archival
    }

    static func presentation(
        profile: NoxMemoryAgingProfile?,
        input: Input
    ) -> NoxTimelineRowPresentation {
        let state = temporalState(profile: profile, input: input)
        let weight = input.temporalWeight ?? input.continuityGravity
        let emphasis = min(1, max(0.35, weight))

        switch state {
        case .active:
            return NoxTimelineRowPresentation(
                temporalState: .active,
                titleOpacity: 0.92,
                metadataOpacity: 0.58,
                detailOpacity: 0.48,
                iconOpacity: 1,
                suppressDuration: false,
                relationLine: nil
            )
        case .fading:
            return NoxTimelineRowPresentation(
                temporalState: .fading,
                titleOpacity: 0.88,
                metadataOpacity: 0.5,
                detailOpacity: 0.42,
                iconOpacity: 0.82,
                suppressDuration: true,
                relationLine: nil
            )
        case .dormant:
            return NoxTimelineRowPresentation(
                temporalState: .dormant,
                titleOpacity: 0.84,
                metadataOpacity: 0.44,
                detailOpacity: 0.36,
                iconOpacity: 0.68,
                suppressDuration: true,
                relationLine: nil
            )
        case .archival:
            return NoxTimelineRowPresentation(
                temporalState: .archival,
                titleOpacity: 0.78,
                metadataOpacity: 0.38,
                detailOpacity: 0.32,
                iconOpacity: 0.55,
                suppressDuration: true,
                relationLine: nil
            )
        case .resurfacing:
            let titleBoost = 0.9 + emphasis * 0.06
            return NoxTimelineRowPresentation(
                temporalState: .resurfacing,
                titleOpacity: min(0.96, titleBoost),
                metadataOpacity: 0.56,
                detailOpacity: 0.46,
                iconOpacity: 0.92,
                suppressDuration: true,
                relationLine: nil
            )
        }
    }
}
