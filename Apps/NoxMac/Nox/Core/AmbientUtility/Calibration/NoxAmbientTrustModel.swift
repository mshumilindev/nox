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

nonisolated enum NoxAmbientTrustModel {

    static func globalRestraint(
        trust: NoxAmbientTrustState,
        fatigue: Double,
        interruptionCost: Double
    ) -> Double {
        var restraint = trust.trustScore

        restraint -= fatigue * 0.25
        restraint -= interruptionCost * 0.15
        restraint += min(0.08, Double(trust.suppressedUtilityCount) * 0.01)

        return min(1, max(0.32, restraint))
    }
}
