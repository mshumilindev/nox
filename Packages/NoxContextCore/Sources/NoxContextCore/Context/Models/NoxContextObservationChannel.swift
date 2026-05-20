import Foundation
import NoxCore

/// What Nox can or cannot observe on this Mac — explicit, not silent failure.
public enum NoxContextObservationChannel: String, Codable, Sendable, CaseIterable, Identifiable {
    case foregroundApp
    case windowTitle
    case browserURL
    case browserDomain
    case browserPageTitle
    case interactionSignals
    case mediaMetadata
    case screenContext
    case accessibility
    case automation

    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foregroundApp: "Foreground app"
        case .windowTitle: "Window title"
        case .browserURL: "Browser URL"
        case .browserDomain: "Browser domain"
        case .browserPageTitle: "Browser page title"
        case .interactionSignals: "Interaction signals"
        case .mediaMetadata: "Media metadata"
        case .screenContext: "Screen context"
        case .accessibility: "Accessibility"
        case .automation: "Automation"
        }
    }
}

public struct NoxContextObservationStatus: Equatable, Sendable, Identifiable {
    let channel: NoxContextObservationChannel
    let isAvailable: Bool
    let blocker: String?

    public var id: String { channel.rawValue }
}
