import Foundation

struct NoxWorkSession: Equatable, Sendable {
    let id: String
    var startedAt: Date
    var endedAt: Date?
    var primaryApp: String
    var primaryBundleId: String
    var interruptionCount: Int
    var appSwitchCount: Int
    var confidence: Double
    var state: NoxWorkSessionState

    var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }

    var summaryLine: String {
        let minutes = max(1, durationMs / 60_000)
        if endedAt == nil {
            return NoxHumanContextCopy.appInFocus(appName: primaryApp, minutes: minutes)
        }
        return NoxHumanContextCopy.appWasInFocus(appName: primaryApp, minutes: minutes)
    }
}

enum NoxWorkSessionState: String, Sendable {
    case active
    case ended
}
