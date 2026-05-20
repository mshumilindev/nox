import Foundation

/// Conceptual navigation — not dashboard tabs.
nonisolated enum NoxSemanticDestination: String, CaseIterable, Identifiable, Codable, Sendable {
    case now
    case presence
    case threads
    case memory
    case patterns
    case observatory
    case reflections
    case local
    case trust

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now: "Now"
        case .presence: "Presence"
        case .threads: "Threads"
        case .memory: "Memory"
        case .patterns: "Patterns"
        case .observatory: "Observatory"
        case .reflections: "Reflections"
        case .local: "Local"
        case .trust: "Trust"
        }
    }

    var symbolName: String {
        switch self {
        case .now: "waveform.path"
        case .presence: "laptopcomputer.and.iphone"
        case .threads: "link"
        case .memory: "clock.arrow.circlepath"
        case .patterns: "square.grid.3x3"
        case .observatory: "scope"
        case .reflections: "text.quote"
        case .local: "internaldrive"
        case .trust: "shield.lefthalf.filled"
        }
    }

    /// Compact menu bar order — mirrors expanded rail grouping.
    static var compactRailOrder: [NoxSemanticDestination] {
        [.now, .presence, .threads, .memory, .observatory, .patterns, .reflections, .local, .trust]
    }

}
