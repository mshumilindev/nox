import Foundation

enum NoxConnectorExplainability {

    static func summary(
        preferences: NoxConnectorPreferences,
        calendarAccess: NoxCalendarAccessState,
        contributed: [NoxConnectorKind]
    ) -> NoxConnectorExplainabilitySummary {
        var collected: [String] = []
        var notCollected: [String] = [
            "Email bodies and message text",
            "Meeting titles and attendee lists",
            "Cloud sync or remote connector storage"
        ]

        if preferences.calendarEnabled, calendarAccess == .authorized {
            collected.append("Calendar timing and density (generalized)")
        } else if preferences.calendarEnabled {
            notCollected.append("Calendar (permission not granted)")
        }

        if preferences.communicationPressureEnabled {
            collected.append("Communication cadence from local activity metadata")
        }

        if preferences.continuityEnrichmentPaused {
            collected = []
            notCollected.append("Related-activity signals are paused")
        }

        let collectedSummary = collected.isEmpty
            ? "Connector enrichment is off or waiting for permission."
            : collected.joined(separator: " · ")

        return NoxConnectorExplainabilitySummary(
            contributedCategories: contributed,
            collectedSummary: collectedSummary,
            notCollectedSummary: notCollected.joined(separator: " · "),
            provenanceLines: provenanceLines(
                preferences: preferences,
                calendarAccess: calendarAccess,
                contributed: contributed
            )
        )
    }

    static func inferenceReason(for snapshot: NoxConnectorContinuitySnapshot) -> NoxInferenceReason? {
        guard let signal = snapshot.generalizedSignals.first ?? snapshot.pressureSignals.first.map({
            NoxGeneralizedSignal(
                id: $0.id,
                kind: $0.kind,
                label: $0.label,
                confidence: $0.confidence,
                observedAt: $0.observedAt
            )
        }) else { return nil }

        return NoxInferenceReason(
            id: "connector-\(signal.id)",
            headline: NoxEmotionalSafetyCopy.sanitize(signal.label),
            detail: snapshot.explainability.collectedSummary,
            source: .connectorSignal
        )
    }

    private static func provenanceLines(
        preferences: NoxConnectorPreferences,
        calendarAccess: NoxCalendarAccessState,
        contributed: [NoxConnectorKind]
    ) -> [String] {
        var lines: [String] = []
        if contributed.contains(.calendar) {
            lines.append("Calendar contributed generalized timing states only.")
        }
        if contributed.contains(.communication) {
            lines.append("Communication pressure uses app-family metadata — not inbox content.")
        }
        if preferences.continuityEnrichmentPaused {
            lines.append("Enrichment paused — Mac activity awareness may continue.")
        }
        if preferences.calendarEnabled && calendarAccess != .authorized {
            lines.append("Calendar connector is enabled but not authorized on this Mac.")
        }
        return lines
    }
}
