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

struct NoxTimelineRecord: Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let timestamp: Date
    let source: String
    let appName: String?
    let bundleId: String?
    let windowTitle: String?
    let durationMs: Int?
    let metadataJson: String?
    let displayText: String
}
