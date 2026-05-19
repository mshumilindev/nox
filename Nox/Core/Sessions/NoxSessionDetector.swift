import Foundation

struct NoxSessionDetector {
    private(set) var currentSession: NoxWorkSession?
    private var productivityStartedAt: Date?
    private var lastNonProductiveAt: Date?
    private var interruptionStartedAt: Date?

    private let startThreshold: TimeInterval = 300
    private let endIdleThreshold: TimeInterval = 600
    private let endNonProductiveThreshold: TimeInterval = 600
    private let interruptionMaxDuration: TimeInterval = 90

    mutating func ingest(
        snapshot: NoxActivitySnapshot,
        isProductive: Bool,
        eventBus: (NoxEvent) -> Void
    ) -> NoxWorkSession? {
        let now = snapshot.capturedAt

        if snapshot.isResting {
            return endSessionIfNeeded(at: now, eventBus: eventBus)
        }

        if isProductive {
            lastNonProductiveAt = nil
            if productivityStartedAt == nil {
                productivityStartedAt = now
            }
            if currentSession == nil,
               let started = productivityStartedAt,
               now.timeIntervalSince(started) >= startThreshold {
                let session = NoxWorkSession(
                    id: UUID().uuidString,
                    startedAt: now,
                    endedAt: nil,
                    primaryApp: snapshot.appName,
                    primaryBundleId: snapshot.bundleId,
                    interruptionCount: 0,
                    appSwitchCount: 0,
                    confidence: 0.7,
                    state: .active
                )
                currentSession = session
                eventBus(
                    NoxEvent(
                        type: .sessionStarted,
                        payload: .session(
                            SessionPayload(
                                sessionId: session.id,
                                primaryApp: session.primaryApp,
                                primaryBundleId: session.primaryBundleId,
                                durationMs: 0,
                                confidence: session.confidence,
                                state: session.state.rawValue
                            )
                        )
                    )
                )
            } else if var session = currentSession {
                if interruptionStartedAt != nil {
                    session.interruptionCount += 1
                    interruptionStartedAt = nil
                }
                currentSession = session
            }
        } else {
            if currentSession != nil {
                if interruptionStartedAt == nil {
                    interruptionStartedAt = now
                } else if let started = interruptionStartedAt,
                          now.timeIntervalSince(started) <= interruptionMaxDuration {
                    // short interruption, keep session
                } else {
                    lastNonProductiveAt = now
                }
            } else {
                productivityStartedAt = nil
            }

            if let lastNonProductiveAt,
               now.timeIntervalSince(lastNonProductiveAt) >= endNonProductiveThreshold {
                return endSessionIfNeeded(at: now, eventBus: eventBus)
            }
        }

        return currentSession
    }

    mutating func recordAppSwitch() {
        guard var session = currentSession else { return }
        session.appSwitchCount += 1
        currentSession = session
    }

    mutating func restore(session: NoxWorkSession) {
        currentSession = session
        productivityStartedAt = session.startedAt
        lastNonProductiveAt = nil
        interruptionStartedAt = nil
    }

    func exportCurrentSession() -> NoxWorkSession? {
        currentSession
    }

    private mutating func endSessionIfNeeded(
        at date: Date,
        eventBus: (NoxEvent) -> Void
    ) -> NoxWorkSession? {
        guard var session = currentSession else {
            productivityStartedAt = nil
            return nil
        }

        session.endedAt = date
        session.state = .ended
        session.confidence = min(1.0, 0.6 + Double(session.appSwitchCount) * 0.02)
        currentSession = nil
        productivityStartedAt = nil
        lastNonProductiveAt = nil
        interruptionStartedAt = nil

        eventBus(
            NoxEvent(
                type: .sessionEnded,
                payload: .session(
                    SessionPayload(
                        sessionId: session.id,
                        primaryApp: session.primaryApp,
                        primaryBundleId: session.primaryBundleId,
                        durationMs: session.durationMs,
                        confidence: session.confidence,
                        state: session.state.rawValue
                    )
                )
            )
        )

        return session
    }
}
