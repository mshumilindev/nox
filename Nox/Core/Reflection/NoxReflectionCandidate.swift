import Foundation

struct NoxReflectionCandidate: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let text: String
    let confidence: Double
    let createdAt: Date
    let sourceSignals: [String]
}

struct NoxReflectionInput: Equatable, Sendable {
    let periodLabel: String
    let semanticThemes: [String]
    let continuityResumptions: Int
    let fragmentedSessions: Int
    let dominantArcLabels: [String]
    let recurringThreadTitles: [String]
    let observationHours: Int
    let hasPriorDayActivity: Bool
}
