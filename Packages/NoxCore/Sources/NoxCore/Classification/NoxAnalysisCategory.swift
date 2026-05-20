import Foundation

/// Whether activity participates in behavioral / semantic analysis.
public nonisolated enum NoxAnalysisCategory: String, Codable, Sendable {
    case behavioral
    case systemInternal = "system_internal"
    case excludedFromAnalysis = "excluded_from_analysis"

    public var participatesInBehavioralModel: Bool {
        self == .behavioral
    }
}
