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
import CoreGraphics

/// Poll-based interaction signal collection. No semantic inference.
@MainActor
final class NoxInteractionSignalCollector {
    private(set) var isPipelineActive = false
    private var isInteractionActive = false
    private var isTyping = false
    private var lastTypingBurstAt: Date?
    private var lastScrollAt: Date?
    private var lastMouseAt: Date?

    private let typingBurstThreshold = 8
    private var keyEventsInWindow = 0
    private var keyWindowStart: Date?

    func sample(at date: Date = Date(), publish: (NoxEvent) -> Void) {
        isPipelineActive = true
        let keyIdle = Self.secondsSinceLast(.keyDown)
        let mouseIdle = Self.secondsSinceLast(.mouseMoved)
        let scrollIdle = Self.secondsSinceLast(.scrollWheel)

        sampleInteractionActivity(
            keyIdle: keyIdle,
            mouseIdle: mouseIdle,
            at: date,
            publish: publish
        )
        sampleTyping(keyIdle: keyIdle, at: date, publish: publish)
        sampleScroll(scrollIdle: scrollIdle, at: date, publish: publish)
        sampleMouse(mouseIdle: mouseIdle, at: date, publish: publish)
    }

    private func sampleInteractionActivity(
        keyIdle: TimeInterval,
        mouseIdle: TimeInterval,
        at date: Date,
        publish: (NoxEvent) -> Void
    ) {
        let active = keyIdle < 4 || mouseIdle < 4

        if active, !isInteractionActive {
            isInteractionActive = true
            publish(
                NoxEvent(
                    type: .interactionActive,
                    timestamp: date,
                    payload: .interaction(InteractionPayload(kind: .active, intensity: nil))
                )
            )
        } else if !active, isInteractionActive, keyIdle > 30, mouseIdle > 30 {
            isInteractionActive = false
            publish(
                NoxEvent(
                    type: .interactionIdle,
                    timestamp: date,
                    payload: .interaction(InteractionPayload(kind: .idle, intensity: nil))
                )
            )
        }
    }

    private func sampleTyping(keyIdle: TimeInterval, at date: Date, publish: (NoxEvent) -> Void) {
        let typingNow = keyIdle < 1.5

        if typingNow, !isTyping {
            isTyping = true
            publish(
                NoxEvent(
                    type: .typingStarted,
                    timestamp: date,
                    payload: .interaction(InteractionPayload(kind: .typing, intensity: nil))
                )
            )
        } else if !typingNow {
            isTyping = false
        }

        guard typingNow else {
            keyEventsInWindow = 0
            keyWindowStart = nil
            return
        }

        if keyWindowStart == nil {
            keyWindowStart = date
        }
        keyEventsInWindow += 1

        if keyEventsInWindow >= typingBurstThreshold {
            let sinceLastBurst = lastTypingBurstAt.map { date.timeIntervalSince($0) } ?? .infinity
            if sinceLastBurst >= 8 {
                lastTypingBurstAt = date
                publish(
                    NoxEvent(
                        type: .typingBurst,
                        timestamp: date,
                        payload: .interaction(
                            InteractionPayload(kind: .typingBurst, intensity: Double(keyEventsInWindow))
                        )
                    )
                )
            }
            keyEventsInWindow = 0
            keyWindowStart = date
        }
    }

    private func sampleScroll(scrollIdle: TimeInterval, at date: Date, publish: (NoxEvent) -> Void) {
        guard scrollIdle < 2 else { return }
        let sinceLast = lastScrollAt.map { date.timeIntervalSince($0) } ?? .infinity
        guard sinceLast >= 3 else { return }
        lastScrollAt = date
        publish(
            NoxEvent(
                type: .scrollActivity,
                timestamp: date,
                payload: .interaction(InteractionPayload(kind: .scroll, intensity: nil))
            )
        )
    }

    private func sampleMouse(mouseIdle: TimeInterval, at date: Date, publish: (NoxEvent) -> Void) {
        guard mouseIdle < 2 else { return }
        let sinceLast = lastMouseAt.map { date.timeIntervalSince($0) } ?? .infinity
        guard sinceLast >= 4 else { return }
        lastMouseAt = date
        publish(
            NoxEvent(
                type: .mouseActivity,
                timestamp: date,
                payload: .interaction(InteractionPayload(kind: .mouse, intensity: nil))
            )
        )
    }

    private static func secondsSinceLast(_ type: CGEventType) -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: type)
    }
}
