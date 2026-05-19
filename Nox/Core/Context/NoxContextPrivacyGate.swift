import Foundation

/// Universal redaction before UI display and warm persistence.
enum NoxContextPrivacyGate {
    static func persistableSnapshot(from evidence: NoxContextEvidence) -> NoxPersistableContextSnapshot {
        NoxPersistableContextSnapshot(
            dominantContextType: evidence.safeOutput.dominantContextType.rawValue,
            safeLabel: evidence.safeOutput.displayLabel,
            sensitivityLevel: evidence.semantic.sensitivityLevel.rawValue,
            confidence: evidence.semantic.dominanceScore,
            redacted: evidence.safeOutput.detailsRedacted,
            evaluatedAt: evidence.evaluatedAt
        )
    }

    static func redactContentIdentity(_ identity: NoxContentIdentityEvidence, sensitivity: NoxSensitivityLevel) -> NoxContentIdentityEvidence {
        guard sensitivity != .normal else { return identity }
        return NoxContentIdentityEvidence(
            contextTitle: nil,
            contextSubtitle: nil,
            documentTitle: nil,
            projectOrWorkspaceTitle: nil,
            activeResourceName: nil,
            domain: nil,
            mediaTitle: nil,
            fileName: nil,
            conversationOrChannelName: nil
        )
    }
}

struct NoxPersistableContextSnapshot: Codable, Equatable, Sendable {
    let dominantContextType: String
    let safeLabel: String
    let sensitivityLevel: String
    let confidence: Double
    let redacted: Bool
    let evaluatedAt: Date
}
