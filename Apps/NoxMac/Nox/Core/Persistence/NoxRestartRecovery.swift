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

struct NoxRestartRecoveryResult: Sendable {
    let resumedSession: NoxWorkSession?
    let interruptedSessionCount: Int
    let closedOrphanSpans: Int
    let continuityNote: String?
}

enum NoxRestartRecovery {
    static let resumeGapSeconds: TimeInterval = 15 * 60

    static func recover(
        sessionStore: NoxSessionStore,
        memoryStore: NoxMemoryStore,
        ambient: NoxAmbientState,
        currentBundleId: String?
    ) async throws -> NoxRestartRecoveryResult {
        let now = Date()
        var interruptedCount = 0
        var continuityNote: String?

        if let active = try await sessionStore.activeSession() {
            if shouldResume(session: active, ambient: ambient, currentBundleId: currentBundleId, now: now) {
                continuityNote = resumeNote(session: active, ambient: ambient)
                return NoxRestartRecoveryResult(
                    resumedSession: active,
                    interruptedSessionCount: 0,
                    closedOrphanSpans: try await closeOrphanSpans(memoryStore: memoryStore, at: now),
                    continuityNote: continuityNote
                )
            }

            try await sessionStore.closeActiveSessions(at: now, reason: .interruptedByRestart)
            interruptedCount = 1
            continuityNote = "Previous session interrupted by restart"
        }

        let closedSpans = try await closeOrphanSpans(memoryStore: memoryStore, at: now)
        if closedSpans > 0, continuityNote == nil {
            continuityNote = "Recovered open context from before restart"
        }

        return NoxRestartRecoveryResult(
            resumedSession: nil,
            interruptedSessionCount: interruptedCount,
            closedOrphanSpans: closedSpans,
            continuityNote: continuityNote
        )
    }

    private static func shouldResume(
        session: NoxWorkSession,
        ambient: NoxAmbientState,
        currentBundleId: String?,
        now: Date
    ) -> Bool {
        guard let shutdown = ambient.lastShutdownAt else { return false }
        let gap = now.timeIntervalSince(shutdown)
        guard gap <= resumeGapSeconds else { return false }
        if let currentBundleId, currentBundleId == session.primaryBundleId {
            return true
        }
        if ambient.lastActiveBundleId == session.primaryBundleId {
            return true
        }
        return false
    }

    private static func resumeNote(session: NoxWorkSession, ambient: NoxAmbientState) -> String {
        let minutes = max(1, Int(Date().timeIntervalSince(session.startedAt) / 60))
        if let shutdown = ambient.lastShutdownAt {
            let gapMinutes = max(1, Int(Date().timeIntervalSince(shutdown) / 60))
            return "Resumed session in \(session.primaryApp) · \(minutes)m total · gap \(gapMinutes)m"
        }
        return "Resumed session in \(session.primaryApp)"
    }

    private static func closeOrphanSpans(memoryStore: NoxMemoryStore, at date: Date) async throws -> Int {
        try await memoryStore.closeOpenSpans(at: date)
    }
}
