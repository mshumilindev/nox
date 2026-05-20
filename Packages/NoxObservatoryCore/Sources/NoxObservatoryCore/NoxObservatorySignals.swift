import Foundation
import NoxSemanticCore
import NoxContinuityCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxObservatorySignal: String, CaseIterable, Identifiable, Sendable {
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

    public var id: String { rawValue }

    public var title: String {
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

    public var description: String {
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
}

public enum NoxObservatorySignalGroup: String, CaseIterable, Identifiable, Sendable {
    case focusField
    case strainField
    case recoveryField
    case coordinationField
    case rhythmField

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .focusField: "Focus field"
        case .strainField: "Strain field"
        case .recoveryField: "Recovery field"
        case .coordinationField: "Coordination"
        case .rhythmField: "Rhythm"
        }
    }

    public var description: String {
        switch self {
        case .focusField: "Focus continuity and deep work collapsed into one readable trace."
        case .strainField: "Fragmentation, switching, overload, and interruptions as one pressure trace."
        case .recoveryField: "Recovery and passive decompression as one decompression trace."
        case .coordinationField: "Communication and cadence pressure."
        case .rhythmField: "Stability across work and recovery cycles."
        }
    }

    public var signals: [NoxObservatorySignal] {
        switch self {
        case .focusField: [.focusContinuity, .deepWork]
        case .strainField: [.fragmentation, .contextSwitching, .overloadPressure, .interruptionDensity]
        case .recoveryField: [.recovery, .passiveDecompression]
        case .coordinationField: [.coordinationLoad]
        case .rhythmField: [.rhythmStability]
        }
    }
}
