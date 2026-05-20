import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public nonisolated struct NoxContinuityThread: Identifiable, Equatable, Sendable {
    public let id: String
    public var semanticType: NoxContinuitySemanticType
    public var title: String
    public var dominantApps: [String]
    public var dominantCategories: [String]
    public var dominantDomains: [String]
    public var continuitySignature: NoxContinuitySignature
    public var firstSeenAt: Date
    public var lastSeenAt: Date
    public var totalActiveDurationMs: Int
    public var totalSessions: Int
    public var totalResumptions: Int
    public var continuityStrength: Double
    public var recurrenceStrength: Double
    public var interruptionPattern: String
    public var currentStatus: NoxContinuityStatus
    public var recentMemoryIds: [String]
    public var linkedSpanIds: [String]
    public var linkedSessionIds: [String]
    public var supportingSignals: [NoxContinuityMatchComponent]
    public var confidence: Double
    public var lastResumedAt: Date?
    public var temporalPatterns: [String]
    public var decayState: NoxContinuityDecayState
    public var sensitivityLevel: NoxSensitivityLevel

    public init(
        id: String,
        semanticType: NoxContinuitySemanticType,
        title: String,
        dominantApps: [String],
        dominantCategories: [String],
        dominantDomains: [String],
        continuitySignature: NoxContinuitySignature,
        firstSeenAt: Date,
        lastSeenAt: Date,
        totalActiveDurationMs: Int,
        totalSessions: Int,
        totalResumptions: Int,
        continuityStrength: Double,
        recurrenceStrength: Double,
        interruptionPattern: String,
        currentStatus: NoxContinuityStatus,
        recentMemoryIds: [String],
        linkedSpanIds: [String],
        linkedSessionIds: [String],
        supportingSignals: [NoxContinuityMatchComponent],
        confidence: Double,
        lastResumedAt: Date?,
        temporalPatterns: [String],
        decayState: NoxContinuityDecayState,
        sensitivityLevel: NoxSensitivityLevel
    ) {
        self.id = id
        self.semanticType = semanticType
        self.title = title
        self.dominantApps = dominantApps
        self.dominantCategories = dominantCategories
        self.dominantDomains = dominantDomains
        self.continuitySignature = continuitySignature
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.totalActiveDurationMs = totalActiveDurationMs
        self.totalSessions = totalSessions
        self.totalResumptions = totalResumptions
        self.continuityStrength = continuityStrength
        self.recurrenceStrength = recurrenceStrength
        self.interruptionPattern = interruptionPattern
        self.currentStatus = currentStatus
        self.recentMemoryIds = recentMemoryIds
        self.linkedSpanIds = linkedSpanIds
        self.linkedSessionIds = linkedSessionIds
        self.supportingSignals = supportingSignals
        self.confidence = confidence
        self.lastResumedAt = lastResumedAt
        self.temporalPatterns = temporalPatterns
        self.decayState = decayState
        self.sensitivityLevel = sensitivityLevel
    }

    public var durationText: String {
        let minutes = totalActiveDurationMs / 60_000
        if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }
        return "\(max(1, minutes))m"
    }
}
