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

nonisolated enum NoxPatternConfidenceModel {
    static let minimumDisplay: Double = 0.55
    static let minimumPersist: Double = 0.58
    static let minimumStructure: Double = 0.52

    static func gate<T>(_ items: [T], confidence: (T) -> Double, limit: Int = 6) -> [T] {
        items
            .filter { confidence($0) >= minimumDisplay }
            .sorted { confidence($0) > confidence($1) }
            .prefix(limit)
            .map { $0 }
    }
}
