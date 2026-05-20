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

struct NoxInferenceReason: Identifiable, Equatable, Sendable {
    let id: String
    let headline: String
    let detail: String?
    let source: NoxExplanationSource
}

enum NoxExplanationSource: String, Sendable {
    case liveSignal
    case memorySpan
    case continuityThread
    case reflection
    case emergence
    case connectorSignal
}
