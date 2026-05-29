import Foundation
import AppKit
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
import NoxShrineCore
import CoreGraphics

@preconcurrency import ApplicationServices

nonisolated struct NoxPermissionService: Sendable {
    func currentCapabilities() -> NoxCapabilityState {
        let accessibility = AXIsProcessTrusted()
        let screenRecording = CGPreflightScreenCaptureAccess()
        let appAwareness = true
        let windowAwareness = accessibility || screenRecording

        return NoxCapabilityState(
            accessibilityGranted: accessibility,
            screenRecordingGranted: screenRecording,
            appAwarenessAvailable: appAwareness,
            windowAwarenessAvailable: windowAwareness,
            interactionSignalsAvailable: false
        )
    }

    func currentState() -> NoxPermissionState {
        currentCapabilities().derivedPermissionState()
    }

    func requestAccessibilityPrompt() {
        let options = [Self.accessibilityPromptOptionKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static let accessibilityPromptOptionKey: String = {
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    }()

    @MainActor
    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @MainActor
    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
