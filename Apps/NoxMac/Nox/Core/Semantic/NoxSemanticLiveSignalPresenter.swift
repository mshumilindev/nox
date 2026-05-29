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

@MainActor
enum NoxSemanticLiveSignalPresenter {
    private static var lastEmitted: [String: Date] = [:]
    private static var lastContextKey: String?
    private static let cooldownSeconds: TimeInterval = 18
    private static let minimumContinuitySeconds: TimeInterval = 4

    static func reset() {
        lastEmitted.removeAll()
        lastContextKey = nil
    }

    static func makeSignal(
        from inference: NoxSemanticInference,
        at date: Date = Date(),
        observationContinuitySeconds: TimeInterval = 0
    ) -> NoxLiveSignal? {
        guard inference.shouldSurface,
              inference.confidence >= NoxSemanticConfidence.liveSignalThreshold else {
            return nil
        }

        guard observationContinuitySeconds >= requiredContinuitySeconds(for: inference) ||
                inference.confidence >= 0.55 else {
            return nil
        }

        guard let phrase = NoxSemanticLabelCatalog.semanticPulseTitle(from: inference),
              !phrase.isEmpty else {
            return nil
        }

        let key = phrase.lowercased()
        let contextKey = contextFingerprint(inference)

        let cooldown = cooldownSecondsFor(inference)
        if let last = lastEmitted[key], date.timeIntervalSince(last) < cooldown {
            return nil
        }

        if lastContextKey == contextKey,
           let last = lastEmitted.values.max(),
           date.timeIntervalSince(last) < cooldown {
            return nil
        }

        lastEmitted[key] = date
        lastContextKey = contextKey

        return NoxLiveSignal(
            id: "semantic-\(key.hashValue)-\(Int(date.timeIntervalSince1970))",
            timestamp: date,
            text: phrase,
            kind: .awareness,
            lifecycle: .transient(75)
        )
    }

    private static func requiredContinuitySeconds(for inference: NoxSemanticInference) -> TimeInterval {
        switch inference.state {
        case .passiveConsumption, .reading:
            return 2
        case .writing, .activeInteraction, .waiting:
            return 5
        default:
            switch inference.fusionLabel {
            case .likelyGaming, .likelyInteractiveBrowsing, .likelyFileTransfer, .likelyCommunication,
                 .likelyPassiveEntertainment:
                return 10
            default:
                return minimumContinuitySeconds
            }
        }
    }

    private static func cooldownSecondsFor(_ inference: NoxSemanticInference) -> TimeInterval {
        switch inference.state {
        case .writing, .activeInteraction, .waiting:
            return 20
        default:
            return cooldownSeconds
        }
    }

    private static func contextFingerprint(_ inference: NoxSemanticInference) -> String {
        "\(inference.state.rawValue)-\(inference.fusionLabel.rawValue)-\(inference.browserCategory.rawValue)-\(inference.aiWorkflow?.rawValue ?? "")"
    }
}
