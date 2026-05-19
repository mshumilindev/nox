import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct NoxPermissionService: Sendable {
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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

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
