import Foundation

/// Whether activity participates in behavioral / semantic analysis.
enum NoxAnalysisCategory: String, Codable, Sendable {
    case behavioral
    case systemInternal = "system_internal"
    case excludedFromAnalysis = "excluded_from_analysis"

    var participatesInBehavioralModel: Bool {
        self == .behavioral
    }
}
