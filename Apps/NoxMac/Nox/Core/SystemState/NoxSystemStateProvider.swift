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
import IOKit.ps
import Intents

#if canImport(Intents)
#endif

protocol NoxSystemStateProviding {
    func snapshot(
        noxCaffeinateActive: Bool,
        at date: Date
    ) -> NoxSystemStateSnapshot
}

@MainActor
struct NoxSystemStateProvider: NoxSystemStateProviding {
    func snapshot(noxCaffeinateActive: Bool, at date: Date = Date()) -> NoxSystemStateSnapshot {
        let battery = Self.readBattery()
        let focus = Self.readFocus()
        let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let hour = Calendar.current.component(.hour, from: date)
        let externalDisplay = NSScreen.screens.count > 1
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        return NoxSystemStateSnapshot(
            focusReading: focus.reading,
            focusAuthorized: focus.authorized,
            displaySleepPrevented: noxCaffeinateActive,
            noxCaffeinateActive: noxCaffeinateActive,
            batteryLevel: battery.level,
            isCharging: battery.charging,
            onExternalPower: battery.onAC,
            lowPowerModeEnabled: lowPower,
            externalDisplayConnected: externalDisplay,
            appearanceIsDark: appearance,
            hourOfDay: hour,
            signalsReliable: battery.reliable || focus.authorized
        )
    }

    private static func readBattery() -> (level: Double?, charging: Bool, onAC: Bool, reliable: Bool) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let rawSources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let source = rawSources.first,
              let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return (nil, false, false, false)
        }

        let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = max(1, description[kIOPSMaxCapacityKey] as? Int ?? 100)
        let charging = (description[kIOPSIsChargingKey] as? Bool) ?? false
        let onAC = charging || ((description[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue)
        let level = Double(current) / Double(maxCapacity)
        return (Swift.min(1, Swift.max(0, level)), charging, onAC, true)
    }

    private static func readFocus() -> (reading: NoxFocusSystemReading, authorized: Bool) {
        #if canImport(Intents)
        if #available(macOS 12.0, *) {
            return NoxFocusStatusReader.current()
        }
        #endif
        return (.unknown, false)
    }
}

#if canImport(Intents)
@available(macOS 12.0, *)
private enum NoxFocusStatusReader {
    static func current() -> (reading: NoxFocusSystemReading, authorized: Bool) {
        let center = INFocusStatusCenter.default
        let authorized = center.authorizationStatus == .authorized
        guard authorized else { return (.unknown, false) }
        let status = center.focusStatus
        if status.isFocused == true {
            return (.focused, true)
        }
        if status.isFocused == false {
            return (.available, true)
        }
        return (.unknown, true)
    }
}
#endif

struct MockSystemStateProvider: NoxSystemStateProviding {
    var stub: NoxSystemStateSnapshot

    func snapshot(noxCaffeinateActive: Bool, at date: Date) -> NoxSystemStateSnapshot {
        NoxSystemStateSnapshot(
            focusReading: stub.focusReading,
            focusAuthorized: stub.focusAuthorized,
            displaySleepPrevented: noxCaffeinateActive,
            noxCaffeinateActive: noxCaffeinateActive,
            batteryLevel: stub.batteryLevel,
            isCharging: stub.isCharging,
            onExternalPower: stub.onExternalPower,
            lowPowerModeEnabled: stub.lowPowerModeEnabled,
            externalDisplayConnected: stub.externalDisplayConnected,
            appearanceIsDark: stub.appearanceIsDark,
            hourOfDay: stub.hourOfDay,
            signalsReliable: stub.signalsReliable
        )
    }
}
