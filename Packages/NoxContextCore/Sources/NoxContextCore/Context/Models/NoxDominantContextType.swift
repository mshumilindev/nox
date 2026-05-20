import Foundation
import NoxCore

/// Universal human-facing context kinds — not tied to specific apps or sites.
public enum NoxDominantContextType: String, Codable, Sendable, CaseIterable {
    case reading
    case writing
    case watching
    case listening
    case development
    case communication
    case creativeWork
    case gamingInteractive
    case fileTransfer
    case shoppingComparison
    case travelPlanning
    case research
    case privateContext
    case sensitiveContext
    case unknown
    case insufficient
}
