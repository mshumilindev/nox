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

struct NoxSemanticEvaluationSignature: Equatable, Sendable {
    let bundleId: String?
    let windowTitle: String?
    let documentURL: String?
    let isUserIdle: Bool

    init(snapshot: NoxActivitySnapshot) {
        self.bundleId = snapshot.bundleId
        self.windowTitle = snapshot.windowTitle
        self.documentURL = snapshot.documentURL
        self.isUserIdle = snapshot.isUserIdle
    }
}

struct NoxSemanticEvaluationCadence: Equatable, Sendable {
    var lastEvaluatedAt: Date?
    var lastSignature: NoxSemanticEvaluationSignature?

    let stableInterval: TimeInterval
    let idleInterval: TimeInterval

    init(
        stableInterval: TimeInterval = 15,
        idleInterval: TimeInterval = 45
    ) {
        self.stableInterval = stableInterval
        self.idleInterval = idleInterval
    }

    mutating func shouldEvaluate(
        snapshot: NoxActivitySnapshot,
        force: Bool = false,
        now: Date
    ) -> Bool {
        let signature = NoxSemanticEvaluationSignature(snapshot: snapshot)

        if force || lastEvaluatedAt == nil || lastSignature != signature {
            record(signature: signature, at: now)
            return true
        }

        let interval = snapshot.isUserIdle ? idleInterval : stableInterval
        guard let lastEvaluatedAt,
              now.timeIntervalSince(lastEvaluatedAt) >= interval else {
            return false
        }

        record(signature: signature, at: now)
        return true
    }

    mutating func reset() {
        lastEvaluatedAt = nil
        lastSignature = nil
    }

    private mutating func record(signature: NoxSemanticEvaluationSignature, at date: Date) {
        lastSignature = signature
        lastEvaluatedAt = date
    }
}
