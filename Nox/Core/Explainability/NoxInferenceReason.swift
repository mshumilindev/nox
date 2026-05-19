import Foundation

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
