import AppKit
import Foundation

enum NoxSystemActionOutcome: Equatable, Sendable {
    case completed(String)
    case dismissed
    case unavailable(String)
    case noOp
}

@MainActor
enum NoxSystemActionExecutor {

    static func perform(
        _ action: NoxSystemActionCandidate,
        contradictionType: NoxSystemContradictionType?,
        preferences: NoxSystemStatePreferences,
        persistence: inout NoxSystemStatePersistence,
        observationContinuitySeconds: TimeInterval,
        at date: Date = Date()
    ) -> NoxSystemActionOutcome {
        guard NoxSystemActionPermissionModel.allowed(
            action.kind,
            preferences: preferences,
            caffeinateActive: NoxCaffeinateController.shared.isActive(at: date)
        ) else {
            return .unavailable(action.fallbackWhenUnavailable ?? "This action is not available right now.")
        }

        let outcome: NoxSystemActionOutcome
        switch action.kind {
        case .openFocusSettings:
            outcome = openSettings(focusURL) ? .completed("Opened Focus settings.") : .unavailable(action.fallbackWhenUnavailable ?? "Could not open Focus settings.")
        case .openBatterySettings:
            outcome = openSettings(batteryURL) ? .completed("Opened Battery settings.") : .unavailable(action.fallbackWhenUnavailable ?? "Could not open Battery settings.")
        case .startCaffeinate30:
            outcome = startCaffeinate(seconds: 30 * 60, reason: "user-30m", persistence: &persistence, at: date)
        case .startCaffeinate60:
            outcome = startCaffeinate(seconds: 60 * 60, reason: "user-60m", persistence: &persistence, at: date)
        case .startCaffeinateUntilSessionEnd:
            let remaining = max(30 * 60, observationContinuitySeconds + 15 * 60)
            outcome = startCaffeinate(seconds: remaining, reason: "user-session", persistence: &persistence, at: date)
        case .stopCaffeinate:
            if let stopped = NoxCaffeinateController.shared.stop(at: date) {
                persistence.caffeinateSession = stopped
            } else {
                persistence.caffeinateSession?.stoppedAt = date
            }
            outcome = .completed("Stopped display sleep protection.")
        case .reduceResurfacingQuiet:
            persistence.resurfacingQuietUntil = date.addingTimeInterval(2 * 3600)
            outcome = .completed("Reduced resurfacing for a short window.")
        case .dismiss:
            if let contradictionType {
                NoxSystemContradictionSuppressionModel.recordDismissal(
                    type: contradictionType,
                    persistence: &persistence,
                    at: date
                )
            }
            outcome = .dismissed
        }

        appendHistory(
            action: action,
            contradictionType: contradictionType,
            outcome: outcome,
            persistence: &persistence,
            at: date
        )
        return outcome
    }

    private static let focusURL = URL(string: "x-apple.systempreferences:com.apple.Focus-Settings.extension")!
    private static let batteryURL = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!

    private static func openSettings(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    private static func startCaffeinate(
        seconds: TimeInterval,
        reason: String,
        persistence: inout NoxSystemStatePersistence,
        at date: Date
    ) -> NoxSystemActionOutcome {
        guard let session = NoxCaffeinateController.shared.start(durationSeconds: seconds, reason: reason, at: date) else {
            return .unavailable("Could not start display sleep protection.")
        }
        persistence.caffeinateSession = session
        return .completed("Display sleep protection active until \(formattedExpiry(session, at: date)).")
    }

    private static func formattedExpiry(_ session: NoxCaffeinateSession, at date: Date) -> String {
        guard let expires = session.expiresAt else { return "session end" }
        let minutes = max(1, Int(expires.timeIntervalSince(date) / 60))
        return "\(minutes)m from now"
    }

    private static func appendHistory(
        action: NoxSystemActionCandidate,
        contradictionType: NoxSystemContradictionType?,
        outcome: NoxSystemActionOutcome,
        persistence: inout NoxSystemStatePersistence,
        at date: Date
    ) {
        let label: String
        switch outcome {
        case .completed(let text): label = text
        case .dismissed: label = "Dismissed"
        case .unavailable(let text): label = text
        case .noOp: label = "No action"
        }
        let record = NoxSystemActionRecord(
            id: UUID().uuidString,
            actionKind: action.kind,
            contradictionType: contradictionType,
            performedAt: date,
            outcome: label
        )
        persistence.actionHistory.insert(record, at: 0)
        if persistence.actionHistory.count > 24 {
            persistence.actionHistory = Array(persistence.actionHistory.prefix(24))
        }
    }
}
