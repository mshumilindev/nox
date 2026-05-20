import Foundation

/// Cross-cutting privacy/sensitivity classification used by context, semantic, and memory layers.
public enum NoxSensitivityLevel: String, Codable, Sendable {
    case normal
    case personal
    case sensitive
    case privateContext
}
