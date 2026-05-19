import Foundation

enum NoxContinuityDecay {
    private static let activeHours: TimeInterval = 24 * 3600
    private static let fadingDays: TimeInterval = 7 * 24 * 3600
    private static let dormantDays: TimeInterval = 30 * 24 * 3600

    static func apply(to thread: NoxContinuityThread, at date: Date = Date()) -> NoxContinuityThread {
        var updated = thread
        let gap = date.timeIntervalSince(thread.lastSeenAt)
        let state: NoxContinuityDecayState
        if gap <= activeHours {
            state = .active
        } else if gap <= fadingDays {
            state = .fading
        } else if gap <= dormantDays {
            state = .dormant
        } else {
            state = .archived
        }
        updated.decayState = state
        if state == .archived {
            updated.continuityStrength *= 0.85
            updated.currentStatus = .paused
        } else if state == .dormant {
            updated.continuityStrength *= 0.92
        }
        return updated
    }

    static func canResurface(_ thread: NoxContinuityThread, at date: Date = Date()) -> Bool {
        guard thread.decayState != .archived else { return false }
        guard thread.sensitivityLevel == .normal || thread.sensitivityLevel == .personal else {
            return thread.confidence >= NoxContinuityConfidence.resurfaceThreshold + 0.08
        }
        return thread.confidence >= NoxContinuityConfidence.resurfaceThreshold
    }
}
