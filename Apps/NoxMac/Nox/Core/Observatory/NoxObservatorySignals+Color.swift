import SwiftUI
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

extension NoxObservatorySignal {
    var color: Color {
        switch self {
        case .focusContinuity: Color(red: 0.48, green: 0.55, blue: 0.95)
        case .deepWork: Color(red: 0.39, green: 0.42, blue: 0.86)
        case .fragmentation: Color(red: 0.72, green: 0.34, blue: 0.56)
        case .contextSwitching: Color(red: 0.38, green: 0.78, blue: 0.86)
        case .recovery: Color(red: 0.45, green: 0.82, blue: 0.74)
        case .passiveDecompression: Color(red: 0.58, green: 0.78, blue: 0.52)
        case .coordinationLoad: Color(red: 0.86, green: 0.63, blue: 0.38)
        case .overloadPressure: Color(red: 0.62, green: 0.18, blue: 0.34)
        case .interruptionDensity: Color(red: 0.9, green: 0.38, blue: 0.24)
        case .rhythmStability: Color(red: 0.86, green: 0.84, blue: 0.98)
        }
    }
}

extension NoxObservatorySignalGroup {
    var color: Color {
        switch self {
        case .focusField: NoxObservatorySignal.focusContinuity.color
        case .strainField: NoxObservatorySignal.overloadPressure.color
        case .recoveryField: NoxObservatorySignal.recovery.color
        case .coordinationField: NoxObservatorySignal.coordinationLoad.color
        case .rhythmField: NoxObservatorySignal.rhythmStability.color
        }
    }
}
