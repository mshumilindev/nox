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

@MainActor
final class NoxCaffeinateController {
    static let shared = NoxCaffeinateController()

    private var process: Process?
    private(set) var activeSession: NoxCaffeinateSession?

    private init() {}

    func isActive(at date: Date = Date()) -> Bool {
        pruneIfExpired(at: date)
        return activeSession?.isActive == true
    }

    @discardableResult
    func start(
        durationSeconds: TimeInterval?,
        reason: String,
        at date: Date = Date()
    ) -> NoxCaffeinateSession? {
        stop(at: date)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        var arguments = ["-dims"]
        if let durationSeconds {
            arguments.append(contentsOf: ["-t", String(Int(durationSeconds))])
        }
        process.arguments = arguments

        do {
            try process.run()
        } catch {
            return nil
        }

        self.process = process
        let session = NoxCaffeinateSession(
            startedAt: date,
            durationSeconds: durationSeconds,
            reason: reason,
            stoppedAt: nil
        )
        activeSession = session
        return session
    }

    @discardableResult
    func stop(at date: Date = Date()) -> NoxCaffeinateSession? {
        if let process, process.isRunning {
            process.terminate()
        }
        self.process = nil
        guard var session = activeSession else { return nil }
        session.stoppedAt = date
        activeSession = nil
        return session
    }

    func pruneIfExpired(at date: Date = Date()) {
        guard let session = activeSession, session.isActive else { return }
        if let expires = session.expiresAt, date >= expires {
            stop(at: date)
        } else if let process, !process.isRunning {
            stop(at: date)
        }
    }

    func restore(session: NoxCaffeinateSession?, at date: Date = Date()) {
        guard let session, session.isActive else {
            activeSession = session
            return
        }
        if isActive(at: date) {
            activeSession = session
            return
        }
        let remaining: TimeInterval?
        if let expires = session.expiresAt {
            remaining = max(60, expires.timeIntervalSince(date))
        } else {
            remaining = session.durationSeconds
        }
        _ = start(durationSeconds: remaining, reason: session.reason, at: date)
    }
}
