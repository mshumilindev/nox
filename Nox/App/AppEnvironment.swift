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
    var timelineSections: [NoxTimelineSection] = []

    var timelineBlocks: [NoxTimelineBlockItem] {
        timelineSections.flatMap(\.items)
    }
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
    var preferences: NoxAmbientPreferences = .default
    var awarenessSnapshot: NoxAwarenessSnapshot = NoxAwarenessPresenter.snapshot(
        capabilities: .unavailable,
        memoryReadiness: .observing,
        pauseState: .active,
        sensitivity: .normal
    )
    var primaryExplanation: NoxInferenceReason?
    var connectorSnapshot: NoxConnectorContinuitySnapshot = .empty

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

    func setWindowMode(_ mode: NoxWindowMode) {
        mutatePreferences { $0.windowMode = mode }
        NoxAppRuntime.panelState.applyWindowMode(mode, using: self)
    }

    func setNavigationDestination(_ destination: NoxSemanticDestination) {
        mutatePreferences { $0.navigationDestination = destination }
    }

    func setSurfaceDensity(_ density: NoxSurfaceDensity) {
        mutatePreferences { $0.surfaceDensity = density }
    }

    func setObservationPaused(_ paused: Bool) {
        mutatePreferences { $0.pauseState.observationPaused = paused }
    }

    func setSemanticMemoryPaused(_ paused: Bool) {
        mutatePreferences { $0.pauseState.semanticMemoryPaused = paused }
    }

    func setQuietMode(_ mode: NoxQuietMode) {
        mutatePreferences { prefs in
            NoxQuietModeEngine.apply(mode, to: &prefs.pauseState)
        }
    }

    func completeTrustOnboarding() {
        mutatePreferences { $0.hasSeenTrustOnboarding = true }
    }

    /// Reassigns the whole struct so `@Observable` notifies SwiftUI (in-place nested mutation does not).
    private func mutatePreferences(_ mutate: (inout NoxAmbientPreferences) -> Void) {
        var updated = preferences
        mutate(&updated)
        preferences = updated
        Task { await contextService.updatePreferences(updated) }
    }

    func clearRecentMemory() async {
        await contextService.clearRecentMemory()
    }

    func clearSemanticContinuity() async {
        await contextService.clearSemanticContinuity()
    }

    func setCalendarConnectorEnabled(_ enabled: Bool) {
        mutatePreferences { $0.connectors.calendarEnabled = enabled }
    }

    func setCommunicationPressureEnabled(_ enabled: Bool) {
        mutatePreferences { $0.connectors.communicationPressureEnabled = enabled }
    }

    func setContinuityEnrichmentPaused(_ paused: Bool) {
        mutatePreferences { $0.connectors.continuityEnrichmentPaused = paused }
    }

    func requestCalendarAccess() async {
        await contextService.requestCalendarAccess()
    }

    func clearConnectorContinuity() async {
        await contextService.clearConnectorContinuity()
    }
}
