import Foundation

struct NoxPresenceContext: Equatable {
    let capabilities: NoxCapabilityState
    let isUserIdle: Bool
    let idleSeconds: TimeInterval
    let currentBundleId: String?
    let currentAppName: String?
    let currentWindowTitle: String?
    let timeInCurrentApp: TimeInterval
    let recentSwitchCount: Int
    let hasEnoughSignals: Bool
    let focusAnalysis: NoxFocusAnalysis?
}
