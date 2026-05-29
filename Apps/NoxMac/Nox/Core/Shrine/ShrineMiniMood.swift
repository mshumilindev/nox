import Foundation
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

/// Orby face mood (deterministic; not a separate assistant). Maps to `NoxShrineFaceState` for contracts.
enum OrbyMood: String, CaseIterable, Equatable, Sendable {
    case neutral
    case focused
    case deepFocus
    case pleased
    case curious
    case thinking
    case sleepy
    case tired
    case concerned
    case skeptical
    case annoyed
    case alarmed
    case excited
    case overloaded
    case passive
    case muted
    case disconnected
    case nightWatch

    var faceState: NoxShrineFaceState {
        switch self {
        case .neutral, .thinking: .idle
        case .focused, .deepFocus: .focused
        case .pleased, .excited: .pleased
        case .curious, .skeptical: .concerned
        case .sleepy, .tired, .nightWatch: .sleepy
        case .concerned, .overloaded: .concerned
        case .annoyed: .annoyed
        case .alarmed: .alarmed
        case .passive: .passive
        case .muted: .muted
        case .disconnected: .disconnected
        }
    }

    var displayTitle: String {
        switch self {
        case .neutral: "Neutral"
        case .focused: "Focused"
        case .deepFocus: "Deep focus"
        case .pleased: "Pleased"
        case .curious: "Curious"
        case .thinking: "Thinking"
        case .sleepy: "Sleepy"
        case .tired: "Tired"
        case .concerned: "Concerned"
        case .skeptical: "Skeptical"
        case .annoyed: "Annoyed"
        case .alarmed: "Alert"
        case .excited: "Excited"
        case .overloaded: "Overloaded"
        case .passive: "Passive"
        case .muted: "Muted"
        case .disconnected: "Disconnected"
        case .nightWatch: "Night watch"
        }
    }
}

typealias ShrineMiniMood = OrbyMood
