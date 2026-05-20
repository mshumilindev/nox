import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Layer-specific narratives — each horizon answers a different question.
public enum NoxLayerNarrativeBuilder {

    public static func build(facts: NoxRollupFacts, level: NoxMemoryCompressionLevel) -> String {
        guard facts.totalActiveMs > 0 || facts.sessionCount > 0 || facts.childRollupCount > 0 else {
            return "No meaningful activity recorded for this period."
        }

        switch level {
        case .hourly: return buildHourly(facts)
        case .daily: return buildDaily(facts)
        case .weekly: return buildWeekly(facts)
        case .monthly: return buildMonthly(facts)
        case .quarterly: return buildQuarterly(facts)
        case .yearly: return buildYearly(facts)
        case .era: return buildEra(facts)
        }
    }

    // MARK: Hourly — continuity windows

    private static func buildHourly(_ facts: NoxRollupFacts) -> String {
        if let window = facts.hourlyContinuityWindows.first {
            let minutes = max(1, window.durationMs / 60_000)
            return "Short continuity in \(window.appName) (~\(minutes)m)\(window.contextLabel.map { " · \($0)" } ?? "")."
        }
        if let app = facts.dominantApps.first {
            return "Brief activity window centered on \(app.name)."
        }
        return "Light activity continuity within the hour."
    }

    // MARK: Daily — what happened

    private static func buildDaily(_ facts: NoxRollupFacts) -> String {
        var parts: [String] = []
        if let top = facts.dominantApps.first {
            let minutes = max(1, top.durationMs / 60_000)
            parts.append("Primary activity in \(top.name) (~\(minutes)m)")
        }
        if facts.fragmentedMs > facts.focusedMs, facts.fragmentedMs > 0 {
            parts.append("with fragmented stretches")
        } else if facts.focusedMs > 0 {
            parts.append("with sustained focus periods")
        }
        if facts.semanticSpanCount > 0, let semantic = facts.topSemanticTitles.first {
            parts.append("including \(semantic.lowercased())")
        }
        return parts.isEmpty ? "Quiet day with minimal tracked activity." : parts.joined(separator: " ") + "."
    }

    // MARK: Weekly — what repeated

    private static func buildWeekly(_ facts: NoxRollupFacts) -> String {
        if let pattern = facts.repeatedWorkflows.first {
            return "Recurring \(pattern.label) (\(pattern.occurrenceCount)× across the week)."
        }
        if facts.recurringContexts.count >= 2 {
            return "Repeated contexts: \(facts.recurringContexts.prefix(3).joined(separator: ", "))."
        }
        if let top = facts.dominantApps.first {
            return "Consistent week anchored in \(top.name) workflows."
        }
        return "Week without strong recurring rhythms."
    }

    // MARK: Monthly — patterns

    private static func buildMonthly(_ facts: NoxRollupFacts) -> String {
        if let pattern = facts.stablePatterns.first {
            return pattern + "."
        }
        if let category = facts.dominantCategories.first {
            return "Stable \(category.category.lowercased()) focus became the dominant pattern."
        }
        return "Month of mixed activity without a single dominant pattern."
    }

    // MARK: Quarterly — direction

    private static func buildQuarterly(_ facts: NoxRollupFacts) -> String {
        if let theme = facts.directionalThemes.first {
            return "Direction emerging: \(theme)."
        }
        if let shift = facts.majorShifts.first {
            return "Quarterly shift toward \(shift)."
        }
        return "Gradual directional movement across the quarter."
    }

    // MARK: Yearly — change

    private static func buildYearly(_ facts: NoxRollupFacts) -> String {
        if let shift = facts.majorShifts.first {
            return shift + "."
        }
        if let top = facts.dominantApps.first {
            return "Year marked by sustained engagement with \(top.name) and related workflows."
        }
        return "Year of evolving activity without a single dominant narrative."
    }

    // MARK: Era — adaptive life/work phase

    private static func buildEra(_ facts: NoxRollupFacts) -> String {
        if let label = facts.eraLabel {
            if facts.eraThemes.isEmpty {
                return "\(label) — a distinct period of activity and focus."
            }
            return "\(label): \(facts.eraThemes.prefix(3).joined(separator: ", "))."
        }
        if let theme = facts.eraThemes.first {
            return "Era characterized by \(theme)."
        }
        return "A sustained chapter of recurring themes and contexts."
    }
}
