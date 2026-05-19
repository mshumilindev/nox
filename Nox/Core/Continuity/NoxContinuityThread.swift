import Foundation

struct NoxContinuityThread: Identifiable, Equatable, Sendable {
    let id: String
    var semanticType: NoxContinuitySemanticType
    var title: String
    var dominantApps: [String]
    var dominantCategories: [String]
    var dominantDomains: [String]
    var continuitySignature: NoxContinuitySignature
    var firstSeenAt: Date
    var lastSeenAt: Date
    var totalActiveDurationMs: Int
    var totalSessions: Int
    var totalResumptions: Int
    var continuityStrength: Double
    var recurrenceStrength: Double
    var interruptionPattern: String
    var currentStatus: NoxContinuityStatus
    var recentMemoryIds: [String]
    var linkedSpanIds: [String]
    var linkedSessionIds: [String]
    var supportingSignals: [NoxContinuityMatchComponent]
    var confidence: Double
    var lastResumedAt: Date?
    var temporalPatterns: [String]
    var decayState: NoxContinuityDecayState
    var sensitivityLevel: NoxSensitivityLevel

    var durationText: String {
        let minutes = totalActiveDurationMs / 60_000
        if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }
        return "\(max(1, minutes))m"
    }
}
