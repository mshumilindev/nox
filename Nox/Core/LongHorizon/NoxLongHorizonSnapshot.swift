import Foundation

struct NoxLongHorizonNarrative: Identifiable, Equatable, Sendable {
    let id: String
    let horizonLabel: String
    let summary: String
    let periodStart: Date
}

struct NoxLongHorizonSnapshot: Equatable, Sendable {
    let activeThreads: [NoxContinuityThread]
    let emergingPatterns: [NoxEmergingMemoryObservation]
    let recentContinuities: [String]
    let longHorizonNarratives: [NoxLongHorizonNarrative]
    let behavioralRhythms: [NoxTypedMemoryEntity]
    let eraCandidates: [NoxTypedMemoryEntity]
    let semanticArcs: [NoxSemanticArc]
    let reflections: [NoxReflectionCandidate]
    let resurfacingNotes: [String]

    static let empty = NoxLongHorizonSnapshot(
        activeThreads: [],
        emergingPatterns: [],
        recentContinuities: [],
        longHorizonNarratives: [],
        behavioralRhythms: [],
        eraCandidates: [],
        semanticArcs: [],
        reflections: [],
        resurfacingNotes: []
    )
}
