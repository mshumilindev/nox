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

struct NoxLivePulseItem: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
    let timestamp: Date
    let symbolName: String

    init(id: String, text: String, timestamp: Date, symbolName: String = "sparkles") {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.symbolName = symbolName
    }
}

struct NoxLiveDetailItem: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
    let symbolName: String

    init(id: String, text: String, symbolName: String = "circle") {
        self.id = id
        self.text = text
        self.symbolName = symbolName
    }
}

struct NoxLiveContextPresentation: Equatable, Sendable {
    let pulse: [NoxLivePulseItem]
    let detail: [NoxLiveDetailItem]

    static let empty = NoxLiveContextPresentation(pulse: [], detail: [])

    var isEmpty: Bool { pulse.isEmpty && detail.isEmpty }
}
