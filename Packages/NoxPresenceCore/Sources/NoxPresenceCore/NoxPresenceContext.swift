import Foundation
import NoxCore

public struct NoxPresenceContext: Equatable, Sendable {
    public let capabilities: NoxCapabilityState
    public let isUserIdle: Bool
    public let idleSeconds: TimeInterval
    public let currentBundleId: String?
    public let currentAppName: String?
    public let currentWindowTitle: String?
    public let timeInCurrentApp: TimeInterval
    public let recentSwitchCount: Int
    public let hasEnoughSignals: Bool
    public let focusAnalysis: NoxFocusAnalysis?

    public init(
        capabilities: NoxCapabilityState,
        isUserIdle: Bool,
        idleSeconds: TimeInterval,
        currentBundleId: String?,
        currentAppName: String?,
        currentWindowTitle: String?,
        timeInCurrentApp: TimeInterval,
        recentSwitchCount: Int,
        hasEnoughSignals: Bool,
        focusAnalysis: NoxFocusAnalysis?
    ) {
        self.capabilities = capabilities
        self.isUserIdle = isUserIdle
        self.idleSeconds = idleSeconds
        self.currentBundleId = currentBundleId
        self.currentAppName = currentAppName
        self.currentWindowTitle = currentWindowTitle
        self.timeInCurrentApp = timeInCurrentApp
        self.recentSwitchCount = recentSwitchCount
        self.hasEnoughSignals = hasEnoughSignals
        self.focusAnalysis = focusAnalysis
    }
}
