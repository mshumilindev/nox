import Foundation

enum NoxMorningContinuityEngine {

    static func shouldGenerate(
        at date: Date,
        lastGeneratedAt: Date?,
        lastShutdownAt: Date?,
        calendar: Calendar = .current
    ) -> NoxMorningTrigger? {
        let hour = calendar.component(.hour, from: date)
        if let last = lastGeneratedAt, calendar.isDate(last, inSameDayAs: date) {
            if let shutdown = lastShutdownAt,
               date.timeIntervalSince(shutdown) >= 6 * 3600,
               date.timeIntervalSince(last) >= 3600 {
                return .longIdleReturn
            }
            return nil
        }

        if let shutdown = lastShutdownAt,
           !calendar.isDate(shutdown, inSameDayAs: date) {
            return .newDay
        }

        if hour >= 5, hour < 11 {
            return .morningWindow
        }

        if lastGeneratedAt == nil {
            return .appLaunch
        }

        return .appLaunch
    }

    static func buildSnapshot(
        trigger: NoxMorningTrigger,
        at date: Date,
        threads: [NoxContinuityThread],
        semanticSpans: [NoxSemanticMemorySpan],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        continuityNote: String?,
        lastShutdownAt: Date?
    ) -> NoxMorningContinuitySnapshot {
        var lines: [String] = []

        if let continuity = continuityOpening(trigger: trigger, note: continuityNote, shutdown: lastShutdownAt, at: date) {
            lines.append(continuity)
        }

        if let threadLine = threadContinuityLine(threads: threads) {
            lines.append(threadLine)
        }

        if let themeLine = recurringThemeLine(spans: semanticSpans, threads: threads) {
            lines.append(themeLine)
        }

        if let fragmentation = fragmentationLine(focus: focus, stats: stats, spans: semanticSpans) {
            lines.append(fragmentation)
        }

        if lines.isEmpty {
            lines.append(fallbackLine(trigger: trigger, stats: stats))
        }

        return NoxMorningContinuitySnapshot(
            generatedAt: date,
            trigger: trigger,
            lines: Array(lines.prefix(4))
        )
    }

    private static func continuityOpening(
        trigger: NoxMorningTrigger,
        note: String?,
        shutdown: Date?,
        at date: Date
    ) -> String? {
        if let note, note.contains("restart") {
            return "Development activity resumed after a restart."
        }
        switch trigger {
        case .newDay:
            if let shutdown, date.timeIntervalSince(shutdown) < 36 * 3600 {
                return "Activity picked up from yesterday evening."
            }
            return "A new day boundary — recent activity threads remain available."
        case .longIdleReturn:
            return "Activity resumed after time away."
        case .morningWindow, .appLaunch:
            if let note, !note.isEmpty {
                return humanizeNote(note)
            }
            return nil
        }
    }

    private static func humanizeNote(_ note: String) -> String {
        if note.contains("Last observed") {
            return "Recent activity patterns are still forming."
        }
        return note
    }

    private static func threadContinuityLine(threads: [NoxContinuityThread]) -> String? {
        let active = threads
            .filter { $0.decayState != .archived && $0.sensitivityLevel == .normal }
            .sorted { $0.recurrenceStrength > $1.recurrenceStrength }

        guard let top = active.first else { return nil }

        switch top.semanticType {
        case .travelPlanning:
            return "Travel planning activity remains active this week."
        case .research:
            return "Research-related activity appeared repeatedly across recent sessions."
        case .development, .aiDevelopment:
            return "Development activity resumed from recent sessions."
        case .writing:
            return "Writing activity is still present in recent memory."
        case .fragmentedWorkflow:
            return "Attention moved between several contexts recently."
        default:
            if top.totalResumptions >= 2 {
                return "A recurring activity thread returned recently."
            }
            return nil
        }
    }

    private static func recurringThemeLine(
        spans: [NoxSemanticMemorySpan],
        threads: [NoxContinuityThread]
    ) -> String? {
        let titles = spans.map { $0.title.lowercased() }
        let devCount = titles.filter { $0.contains("development") || $0.contains("ai-assisted") }.count
        let researchCount = titles.filter { $0.contains("research") || $0.contains("reading") }.count

        if devCount >= 2 && researchCount >= 1 {
            return "Recent sessions mixed development and research contexts."
        }
        if researchCount >= 2 {
            return "Research-related activity appeared repeatedly across recent sessions."
        }
        if threads.filter({ $0.semanticType == .travelPlanning }).count >= 1 {
            return "Travel planning activity remains active this week."
        }
        return nil
    }

    private static func fragmentationLine(
        focus: NoxFocusAnalysis?,
        stats: NoxMemoryDayStats,
        spans: [NoxSemanticMemorySpan]
    ) -> String? {
        let fragmentedSpans = spans.filter {
            $0.semanticState == .fragmentedInteraction ||
            $0.title.lowercased().contains("fragmented")
        }.count
        let nightSpans = spans.filter {
            Calendar.current.component(.hour, from: $0.startedAt) >= 22
        }.count

        if fragmentedSpans >= 2 && nightSpans >= 1 {
            return "Attention fragmentation increased during late-night activity."
        }
        if let focus, focus.kind == .fragmented {
            return "Recent stretches included fragmented attention between contexts."
        }
        if stats.appSwitchCount >= 10 {
            return "Several context shifts appeared in recent activity."
        }
        return nil
    }

    private static func fallbackLine(trigger: NoxMorningTrigger, stats: NoxMemoryDayStats) -> String {
        if stats.totalActiveMs > 0 {
            return "Recent activity is still forming into patterns."
        }
        switch trigger {
        case .appLaunch:
            return "Nox is observing local activity — patterns will form as sessions repeat."
        case .newDay:
            return "Today is open — patterns will appear as activity repeats."
        case .longIdleReturn:
            return "Welcome back — recent activity threads are still available."
        case .morningWindow:
            return "Morning context is still forming from recent activity."
        }
    }
}
