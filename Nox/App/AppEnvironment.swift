import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {
    var presence: NoxPresenceState = .quiet
    var capabilities: NoxCapabilityState = .unavailable
    var permissionState: NoxPermissionState = .limited
    var liveSignals: [NoxLiveSignal] = []
    var timelineEvents: [NoxTimelineRecord] = []
    var timelineBlocks: [NoxTimelineBlockItem] = []
    var memoryPeriod: NoxMemoryPeriod = .today
    var memorySearchText: String = ""
    var memoryReadiness: NoxMemoryReadiness = .observing
    var memoryEmergence: NoxMemoryEmergence = NoxMemoryEmergence(
        continuitySeconds: 0,
        readiness: .observing,
        liveSignalCount: 0
    )
    var capabilityRows: [NoxCapabilityRow] = []
    var dayStats: NoxMemoryDayStats = .empty
    var daySemanticOverview: String?
    var memoryDensity: Double = 0.45
    var focusAnalysis: NoxFocusAnalysis?
    var memoryMaturity: NoxMemoryMaturity = .transient
    var morningSummary: NoxMorningSummary?
    var longHorizonSnapshot: NoxLongHorizonSnapshot = .empty

    var activeAppName: String?
    var activeBundleId: String?
    var activeWindowTitle: String?
    var activeContextLabel: String?
    var idleSeconds: TimeInterval = 0
    var isUserIdle: Bool = false
    var sessionSummary: String?
    var semanticHint: String?
    var semanticInference: NoxSemanticInference = .hidden
    var appContext: NoxAppContext?
    var contextDebugSnapshot: NoxContextDebugSnapshot?

    let appVersion: String
    let buildNumber: String

    private let contextService = NoxContextService()
    private var didStart = false

    init() {
        let bundle = Bundle.main
        appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        contextService.bind(environment: self)
        Task { @MainActor in
            startIfNeeded()
        }
    }

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        Task {
            await contextService.start()
        }
    }

    func refreshPermissions() {
        contextService.refreshPermissionState()
    }

    func requestAccessibilityAccess() {
        contextService.requestAccessibilityAccess()
    }

    func openAccessibilitySettings() {
        NoxPermissionService().openAccessibilitySettings()
    }

    func openScreenRecordingSettings() {
        NoxPermissionService().openScreenRecordingSettings()
    }

    func setMemoryPeriod(_ period: NoxMemoryPeriod) {
        memoryPeriod = period
        Task { await contextService.reloadMemoryView() }
    }

    func setMemorySearch(_ text: String) {
        memorySearchText = text
        Task { await contextService.reloadMemoryView() }
    }
}
