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

enum NoxReflectionInputBuilder {

    static func build(
        period: NoxMemoryPeriod,
        spans: [NoxSemanticMemorySpan],
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis? = nil,
        weeklyRollups: [NoxMemoryRollupSnapshot] = [],
        behavioral: NoxBehavioralIntelligenceSnapshot = .empty,
        at date: Date = Date()
    ) -> NoxReflectionInput {
        let themes = themeLabels(from: spans, arcs: arcs)
        let resumptions = threads.reduce(0) { $0 + $1.totalResumptions }
        let fragmented = spans.filter {
            $0.semanticState == .fragmentedInteraction ||
            $0.title.lowercased().contains("fragmented")
        }.count

        let lookbackStart = date.addingTimeInterval(-48 * 3600)
        let priorActivity = spans.contains { $0.startedAt < lookbackStart }

        let gatedSignatures = behavioral.signatures.filter(\.isGated)
        let gatedRhythms = behavioral.temporalRhythms.filter {
            $0.confidence >= NoxPatternConfidenceModel.minimumDisplay
        }
        let gatedStructures = behavioral.lifeStructures.filter {
            $0.confidence >= NoxPatternConfidenceModel.minimumStructure
        }

        return NoxReflectionInput(
            periodLabel: period.title,
            semanticThemes: themes,
            continuityResumptions: resumptions,
            fragmentedSessions: fragmented,
            dominantArcLabels: arcs.prefix(3).map(\.label),
            resurfacedArcLabels: arcs
                .filter { $0.continuityState == .resurfaced }
                .sorted { $0.strength > $1.strength }
                .prefix(2)
                .map(\.label),
            recurringThreadTitles: threads
                .filter { $0.recurrenceStrength >= 0.4 }
                .sorted { $0.recurrenceStrength > $1.recurrenceStrength }
                .prefix(3)
                .map(\.title),
            observationHours: max(1, Int(stats.totalActiveMs / 3_600_000)),
            hasPriorDayActivity: priorActivity,
            behavioralPatternLabels: gatedSignatures.prefix(3).map(\.label),
            behavioralPatternDetails: gatedSignatures.prefix(3).map(\.detail),
            temporalRhythmLabels: gatedRhythms.prefix(2).map(\.label),
            temporalRhythmDetails: gatedRhythms.prefix(2).map(\.detail),
            driftObservation: behavioral.drift.map { "\($0.label). \($0.detail)" },
            lifeStructureLabels: gatedStructures.prefix(2).map(\.label),
            lifeStructureDetails: gatedStructures.prefix(2).map(\.detail),
            focusSummary: focusSummary(focus: focus, stats: stats),
            weeklyHorizonSnippet: weeklyRollups.last?.summaryText
        )
    }

    private static func focusSummary(focus: NoxFocusAnalysis?, stats: NoxMemoryDayStats) -> String? {
        if let kind = focus?.kind {
            switch kind {
            case .deepWork:
                return "deep focus blocks"
            case .fragmented:
                return "fragmented attention"
            case .focused:
                return "sustained focus"
            }
        }
        if stats.appSwitchCount >= 12 {
            return "frequent context switching"
        }
        return nil
    }

    private static func themeLabels(
        from spans: [NoxSemanticMemorySpan],
        arcs: [NoxSemanticArc]
    ) -> [String] {
        if !arcs.isEmpty {
            return arcs.prefix(4).map(\.label)
        }
        return Array(Set(spans.map(\.title))).prefix(4).map { $0 }
    }
}
