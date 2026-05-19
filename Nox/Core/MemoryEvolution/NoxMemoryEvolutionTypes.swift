import Foundation

nonisolated enum NoxMemoryAgingBand: String, Codable, Sendable {
    case recentlyActive
    case dormant
    case fading
    case archival
    case resurfacing
}

nonisolated struct NoxMemoryAgingProfile: Equatable, Sendable {
    let subjectId: String
    let band: NoxMemoryAgingBand
    let temporalDistance: Double
    let resurfacingMultiplier: Double
    let structuralWeight: Double
}

nonisolated struct NoxIdentityContinuityInsight: Equatable, Sendable {
    let line: String
    let confidence: Double
}

nonisolated struct NoxEraEvolutionHint: Equatable, Sendable {
    let id: String
    let softLabel: String
    let resonance: Double
    let overlapping: Bool
}

nonisolated struct NoxUnresolvedContinuitySignal: Equatable, Sendable {
    let subjectId: String
    let persistenceScore: Double
    let detail: String
}

nonisolated struct NoxMemoryEvolutionState: Codable, Equatable, Sendable {
    var temporalWeights: [String: Double]
    var eraResonance: [String: Double]
    var unresolvedReturnCounts: [String: Int]
    var ecologyCoupling: [String: Double]
    var lastEvolutionAt: Date?
    var lastLongTermResurfacingAt: Date?

    static let initial = NoxMemoryEvolutionState(
        temporalWeights: [:],
        eraResonance: [:],
        unresolvedReturnCounts: [:],
        ecologyCoupling: [:],
        lastEvolutionAt: nil,
        lastLongTermResurfacingAt: nil
    )
}

nonisolated struct NoxMemoryEvolutionSnapshot: Equatable, Sendable {
    let agingProfiles: [NoxMemoryAgingProfile]
    let longHorizonStructures: [String]
    let identityInsights: [NoxIdentityContinuityInsight]
    let eraHints: [NoxEraEvolutionHint]
    let unresolvedSignals: [NoxUnresolvedContinuitySignal]
    let ecologyNotes: [String]
    let temporalWeights: [String: Double]
    let resilienceScores: [String: Double]
    let longTermResurfacingNotes: [String]
    let temporalCoherenceLine: String?
    let prioritizedThreadIds: [String]
    let prioritizedArcIds: [String]
    let preferSparseSurfaces: Bool

    static let neutral = NoxMemoryEvolutionSnapshot(
        agingProfiles: [],
        longHorizonStructures: [],
        identityInsights: [],
        eraHints: [],
        unresolvedSignals: [],
        ecologyNotes: [],
        temporalWeights: [:],
        resilienceScores: [:],
        longTermResurfacingNotes: [],
        temporalCoherenceLine: nil,
        prioritizedThreadIds: [],
        prioritizedArcIds: [],
        preferSparseSurfaces: false
    )
}
