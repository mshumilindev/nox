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

nonisolated enum NoxNotificationRelevanceModel {

    static func candidate(
        unfinished: [NoxUnfinishedContinuityCandidate],
        behavioral: NoxBehavioralIntelligenceSnapshot,
        receptiveness: NoxInterventionReceptiveness,
        calmness: NoxAdaptiveCalmnessProfile,
        preferSilence: Bool,
        fragmentedReductionActive: Bool
    ) -> NoxAmbientNotificationCandidate? {
        if preferSilence { return nil }

        if fragmentedReductionActive, receptiveness.fragmented {
            return notification(
                id: "notification-fragmentation-quiet",
                kind: "fragmentation_quiet",
                title: "Nox",
                body: "Recent activity has been unusually fragmented. Nox is reducing active resurfacing temporarily.",
                confidence: 0.6
            )
        }

        if let top = unfinished.first, top.resumptions >= 2, top.persistenceScore >= 0.62 {
            return notification(
                id: "notification-unfinished-\(top.id)",
                kind: "unfinished_continuity",
                title: "Nox",
                body: "A previously interrupted activity thread returned again this week.",
                confidence: min(0.7, top.persistenceScore + 0.1)
            )
        }

        if behavioral.signatures.contains(where: { $0.kind == .lateNightWorkCycle }),
           behavioral.signatures.first(where: { $0.kind == .lateNightWorkCycle })?.confidence ?? 0 >= 0.62 {
            return notification(
                id: "notification-late-evening",
                kind: "late_evening_pattern",
                title: "Nox",
                body: "A recurring late-evening activity pattern has remained stable across recent days.",
                confidence: 0.58
            )
        }

        let resumedCount = unfinished.filter { $0.resumptions >= 2 }.count
        if resumedCount >= 2, receptiveness.recoveryOpen {
            return notification(
                id: "notification-multi-resume",
                kind: "structures_resumed",
                title: "Nox",
                body: "Several long-running structures resumed after a quieter period.",
                confidence: 0.57
            )
        }

        return nil
    }

    private static func notification(
        id: String,
        kind: String,
        title: String,
        body: String,
        confidence: Double
    ) -> NoxAmbientNotificationCandidate {
        NoxAmbientNotificationCandidate(
            id: id,
            kind: kind,
            title: title,
            body: NoxEmotionalSafetyCopy.sanitize(body),
            confidence: confidence
        )
    }
}
