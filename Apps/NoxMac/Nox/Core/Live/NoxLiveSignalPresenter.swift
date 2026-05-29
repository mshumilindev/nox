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

enum NoxLiveSignalPresenter {
    static func from(event: NoxEvent) -> NoxLiveSignal? {
        switch event.type {
        case .presenceChanged,
             .typingStarted, .typingBurst, .scrollActivity, .mouseActivity,
             .interactionIdle, .interactionActive:
            return nil
        case .appChanged, .windowChanged, .userIdleStarted, .userIdleEnded,
             .sessionStarted, .sessionEnded, .permissionChanged,
             .systemWake, .systemSleep, .screenLocked, .screenUnlocked:
            let kind = kind(for: event.type)
            let lifecycle: NoxLiveSignalLifecycle
            if event.type == .permissionChanged {
                lifecycle = .transient(90)
            } else {
                lifecycle = .persistent
            }
            return NoxLiveSignal(
                id: event.id.uuidString,
                timestamp: event.timestamp,
                text: NoxTimelinePresenter.displayText(for: event),
                kind: kind,
                lifecycle: lifecycle
            )
        }
    }

    static func appActive(appName: String, contextLabel: String?, at date: Date) -> NoxLiveSignal {
        let detail = contextLabel ?? appName
        return NoxLiveSignal(
            id: UUID().uuidString,
            timestamp: date,
            text: "\(detail) active",
            kind: .app
        )
    }

    static func returned(to appName: String, at date: Date) -> NoxLiveSignal {
        NoxLiveSignal(
            id: UUID().uuidString,
            timestamp: date,
            text: "Returned to \(appName)",
            kind: .app
        )
    }

    static func observing(at date: Date = Date()) -> NoxLiveSignal {
        NoxLiveSignal(
            id: "awareness-observing",
            timestamp: date,
            text: NoxHumanContextCopy.watchingQuietly,
            kind: .awareness,
            lifecycle: .transient(45)
        )
    }

    static func buildingMemory(at date: Date = Date()) -> NoxLiveSignal {
        NoxLiveSignal(
            id: UUID().uuidString,
            timestamp: date,
            text: NoxHumanContextCopy.contextSettlingIntoMemory,
            kind: .awareness,
            lifecycle: .transient(60)
        )
    }

    static func limitedMode(at date: Date = Date()) -> NoxLiveSignal {
        NoxLiveSignal(
            id: "permission-limited-mode",
            timestamp: date,
            text: NoxLiveSignal.limitedObservationText,
            kind: .permission,
            lifecycle: .transient(120)
        )
    }

    static func appLevelAwareness(at date: Date = Date()) -> NoxLiveSignal {
        NoxLiveSignal(
            id: "permission-app-level",
            timestamp: date,
            text: "App awareness enabled",
            kind: .permission,
            lifecycle: .transient(90)
        )
    }

    static func activityResumed(at date: Date = Date()) -> NoxLiveSignal {
        NoxLiveSignal(
            id: UUID().uuidString,
            timestamp: date,
            text: NoxHumanContextCopy.backInMotion,
            kind: .idle
        )
    }

    private static func kind(for type: NoxEventType) -> NoxLiveSignalKind {
        switch type {
        case .appChanged: .app
        case .windowChanged: .window
        case .userIdleStarted, .userIdleEnded: .idle
        case .sessionStarted, .sessionEnded: .session
        case .permissionChanged: .permission
        case .systemWake, .systemSleep, .screenLocked, .screenUnlocked: .system
        default: .awareness
        }
    }
}
