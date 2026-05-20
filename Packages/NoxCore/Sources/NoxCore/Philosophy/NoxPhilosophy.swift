import Foundation

/// Established Nox identity — ambient, human-centered, local-first.
public enum NoxPhilosophy {
    public enum Phase: String, CaseIterable, Sendable {
        case perform = "I perform."
        case rest = "I rest."
        case live = "I live."
        case am = "I am."
    }

    public static let phases: [Phase] = [.perform, .rest, .live, .am]

    public static let inline = "I perform. I rest. I live. I am."

    public static let localNote = "Everything stays on this Mac."

    public enum Emphasis: Sendable {
        case balanced
        case perform
        case rest
        case live
    }

    /// Subtle presence-aware emphasis — never rotates copy, only softens/lifts lines.
    public static func emphasis(for presence: NoxPresenceState) -> Emphasis {
        switch presence {
        case .resting, .idle, .quiet:
            return .rest
        case .focused, .flow, .active:
            return .perform
        case .distracted, .limited:
            return .live
        }
    }

    public static func lineOpacity(for phase: Phase, emphasis: Emphasis) -> Double {
        let soft = 0.38
        let mid = 0.48
        let lift = 0.56

        switch emphasis {
        case .balanced:
            return mid
        case .perform:
            return phase == .perform ? lift : soft
        case .rest:
            return phase == .rest ? lift : soft
        case .live:
            return phase == .live || phase == .am ? lift : soft
        }
    }
}
