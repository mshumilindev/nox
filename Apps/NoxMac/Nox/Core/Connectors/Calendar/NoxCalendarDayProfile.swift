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

struct NoxCalendarDayProfile: Equatable, Sendable {
    let eventCount: Int
    let meetingMinutes: Int
    let longestGapMinutes: Int
    let afternoonEventCount: Int
    let eveningEventCount: Int
    let backToBackBlocks: Int
    let hasTravelLikeStructure: Bool

    static let empty = NoxCalendarDayProfile(
        eventCount: 0,
        meetingMinutes: 0,
        longestGapMinutes: 0,
        afternoonEventCount: 0,
        eveningEventCount: 0,
        backToBackBlocks: 0,
        hasTravelLikeStructure: false
    )
}

enum NoxCalendarAccessState: Equatable, Sendable {
    case unavailable
    case denied
    case authorized
}
