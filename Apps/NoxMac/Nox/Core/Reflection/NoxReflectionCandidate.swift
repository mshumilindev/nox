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

nonisolated struct NoxReflectionCandidate: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let text: String
    let detailLine: String
    let confidence: Double
    let createdAt: Date
    let sourceSignals: [String]

    init(
        id: String,
        text: String,
        detailLine: String,
        confidence: Double,
        createdAt: Date,
        sourceSignals: [String]
    ) {
        self.id = id
        self.text = text
        self.detailLine = detailLine
        self.confidence = confidence
        self.createdAt = createdAt
        self.sourceSignals = sourceSignals
    }
}

nonisolated struct NoxReflectionInput: Equatable, Sendable {
    let periodLabel: String
    let semanticThemes: [String]
    let continuityResumptions: Int
    let fragmentedSessions: Int
    let dominantArcLabels: [String]
    let resurfacedArcLabels: [String]
    let recurringThreadTitles: [String]
    let observationHours: Int
    let hasPriorDayActivity: Bool
    let behavioralPatternLabels: [String]
    let behavioralPatternDetails: [String]
    let temporalRhythmLabels: [String]
    let temporalRhythmDetails: [String]
    let driftObservation: String?
    let lifeStructureLabels: [String]
    let lifeStructureDetails: [String]
    let focusSummary: String?
    let weeklyHorizonSnippet: String?

    static let empty = NoxReflectionInput(
        periodLabel: "Recently",
        semanticThemes: [],
        continuityResumptions: 0,
        fragmentedSessions: 0,
        dominantArcLabels: [],
        resurfacedArcLabels: [],
        recurringThreadTitles: [],
        observationHours: 1,
        hasPriorDayActivity: false,
        behavioralPatternLabels: [],
        behavioralPatternDetails: [],
        temporalRhythmLabels: [],
        temporalRhythmDetails: [],
        driftObservation: nil,
        lifeStructureLabels: [],
        lifeStructureDetails: [],
        focusSummary: nil,
        weeklyHorizonSnippet: nil
    )
}
