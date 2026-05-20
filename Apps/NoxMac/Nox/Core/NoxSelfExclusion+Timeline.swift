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

extension NoxSelfExclusion {
    static func shouldIgnore(record: NoxTimelineRecord) -> Bool {
        isExcluded(bundleId: record.bundleId, appName: record.appName)
    }
}
