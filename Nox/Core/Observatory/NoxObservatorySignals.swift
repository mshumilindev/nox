import SwiftUI

nonisolated enum NoxObservatorySignal: String, CaseIterable, Identifiable, Sendable {
    case focusContinuity
    case deepWork
    case fragmentation
    case contextSwitching
    case recovery
    case passiveDecompression
    case coordinationLoad
    case overloadPressure
    case interruptionDensity
    case rhythmStability

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusContinuity: "Focus continuity"
        case .deepWork: "Deep work"
        case .fragmentation: "Fragmentation"
        case .contextSwitching: "Context switching"
        case .recovery: "Recovery"
        case .passiveDecompression: "Passive decompression"
        case .coordinationLoad: "Coordination load"
        case .overloadPressure: "Overload pressure"
        case .interruptionDensity: "Interruption density"
        case .rhythmStability: "Rhythm stability"
        }
    }

    var description: String {
        switch self {
        case .focusContinuity: "Sustained spans with low switching and interruption density."
        case .deepWork: "Stable development, research, creative, and productive work."
        case .fragmentation: "Short spans, instability, and interruptions."
        case .contextSwitching: "Switching across apps, windows, and semantic categories."
        case .recovery: "Idle gaps and quiet periods after load."
        case .passiveDecompression: "Sustained passive or media-oriented decompression."
        case .coordinationLoad: "Communication and cadence pressure."
        case .overloadPressure: "Workload pressure with insufficient recovery."
        case .interruptionDensity: "Interruption frequency normalized to the current bucket."
        case .rhythmStability: "Inverse volatility across continuity and recovery cycles."
        }
    }

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

nonisolated enum NoxObservatorySignalGroup: String, CaseIterable, Identifiable, Sendable {
    case focusField
    case strainField
    case recoveryField
    case coordinationField
    case rhythmField

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusField: "Focus field"
        case .strainField: "Strain field"
        case .recoveryField: "Recovery field"
        case .coordinationField: "Coordination"
        case .rhythmField: "Rhythm"
        }
    }

    var description: String {
        switch self {
        case .focusField: "Focus continuity and deep work collapsed into one readable trace."
        case .strainField: "Fragmentation, switching, overload, and interruptions as one pressure trace."
        case .recoveryField: "Recovery and passive decompression as one decompression trace."
        case .coordinationField: "Communication and cadence pressure."
        case .rhythmField: "Stability across work and recovery cycles."
        }
    }

    var signals: [NoxObservatorySignal] {
        switch self {
        case .focusField: [.focusContinuity, .deepWork]
        case .strainField: [.fragmentation, .contextSwitching, .overloadPressure, .interruptionDensity]
        case .recoveryField: [.recovery, .passiveDecompression]
        case .coordinationField: [.coordinationLoad]
        case .rhythmField: [.rhythmStability]
        }
    }

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
