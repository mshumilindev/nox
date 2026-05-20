import Foundation
import Testing
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
@testable import Nox

struct NoxMemoryEvolutionPhase125Tests {

    @Test func temporalCopyPrefersContinuityLanguageOverRawMinutes() {
        let stamp = NoxTemporalContinuityCopyBuilder.temporalStamp(
            lastActiveAt: Date().addingTimeInterval(-120),
            state: .active,
            confidence: 0.7,
            recurrenceStrength: 0.2,
            period: .today
        )
        #expect(stamp == "recently active")
    }

    @Test func unresolvedDetailAvoidsResumptionTelemetry() {
        let thread = NoxContinuityThread(
            id: "t-unresolved",
            semanticType: .development,
            title: "Alpha continuity",
            dominantApps: [],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "a",
                semanticType: .development,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-40 * 86_400),
            lastSeenAt: Date().addingTimeInterval(-3600),
            totalActiveDurationMs: 900_000,
            totalSessions: 5,
            totalResumptions: 4,
            continuityStrength: 0.62,
            recurrenceStrength: 0.48,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.68,
            lastResumedAt: Date(),
            temporalPatterns: [],
            decayState: .active,
            sensitivityLevel: .normal
        )
        let detail = NoxTemporalContinuityCopyBuilder.continuityDetail(
            thread: thread,
            state: .active,
            unresolved: nil
        )
        #expect(detail?.contains("resumption") == false)
        #expect(detail == "interrupted repeatedly today")
    }

    @Test func agingPresenterSoftensDormantVisuals() {
        let profile = NoxMemoryAgingProfile(
            subjectId: "t1",
            band: .dormant,
            temporalDistance: 0.6,
            resurfacingMultiplier: 0.3,
            structuralWeight: 0.4
        )
        let input = NoxMemoryAgingPresenter.Input(
            subjectId: "t1",
            lastActiveAt: Date().addingTimeInterval(-10 * 86_400),
            recurrenceStrength: 0.3,
            continuityGravity: 0.4,
            temporalWeight: 0.35,
            confidence: 0.6,
            isResumed: false,
            at: Date()
        )
        let style = NoxMemoryAgingPresenter.presentation(profile: profile, input: input)
        #expect(style.temporalState == .dormant)
        #expect(style.suppressDuration)
        #expect(style.titleOpacity < 0.9)
    }

    @Test func enrichOrdersResurfacingAboveFleetingActivity() {
        let thread = NoxContinuityThread(
            id: "strong-thread",
            semanticType: .aiDevelopment,
            title: "Build continuity",
            dominantApps: ["Xcode"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "b",
                semanticType: .aiDevelopment,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-7 * 86_400),
            lastSeenAt: Date(),
            totalActiveDurationMs: 3_600_000,
            totalSessions: 6,
            totalResumptions: 3,
            continuityStrength: 0.82,
            recurrenceStrength: 0.75,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.75,
            lastResumedAt: Date(),
            temporalPatterns: [],
            decayState: .active,
            sensitivityLevel: .normal
        )
        let continuityItem = NoxTimelineBlockItem(
            id: thread.id,
            timestamp: thread.lastSeenAt,
            kind: .continuityThread(thread),
            title: thread.title,
            subtitle: nil,
            detailLine: "3 resumptions",
            durationText: "45m",
            category: nil,
            markerSymbol: "link"
        )
        let activitySpan = NoxActivitySpan(
            id: "short-span",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(60),
            appName: "Safari",
            bundleId: "com.apple.Safari",
            windowTitle: nil,
            contextLabel: nil,
            category: .research,
            interruptions: 0,
            focusScore: 0.2,
            metadataJson: nil
        )
        let activityItem = NoxTimelineBlockItem(
            id: activitySpan.id,
            timestamp: activitySpan.startedAt,
            kind: .activitySpan(activitySpan),
            title: "Research",
            subtitle: "Safari",
            detailLine: nil,
            durationText: "1m",
            category: .research,
            markerSymbol: nil
        )
        let sections = [
            NoxTimelineSection(layer: .continuity, items: [continuityItem]),
            NoxTimelineSection(layer: .activity, items: [activityItem])
        ]
        let evolution = NoxMemoryEvolutionSnapshot(
            agingProfiles: NoxMemoryAgingEngine.profiles(threads: [thread], arcs: []),
            longHorizonStructures: [],
            identityInsights: [],
            eraHints: [],
            unresolvedSignals: [],
            ecologyNotes: [],
            temporalWeights: ["strong-thread": 0.85, "short-span": 0.1],
            resilienceScores: [:],
            longTermResurfacingNotes: [],
            temporalCoherenceLine: nil,
            prioritizedThreadIds: ["strong-thread"],
            prioritizedArcIds: [],
            preferSparseSurfaces: false
        )
        let enriched = NoxTemporalMemoryRowPresenter.enrich(
            sections: sections,
            threads: [thread],
            arcs: [],
            evolution: evolution,
            period: .today
        )
        let continuityDetail = enriched.first { $0.layer == .continuity }?.items.first?.detailLine
        #expect(continuityDetail?.contains("resumption") == false)
        let activityDuration = enriched.first { $0.layer == .activity }?.items.first?.durationText
        #expect(activityDuration == nil)
    }
}
