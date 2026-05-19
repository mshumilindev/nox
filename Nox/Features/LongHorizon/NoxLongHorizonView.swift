import SwiftUI

struct NoxLongHorizonView: View {
    let snapshot: NoxLongHorizonSnapshot
    var morningSummary: NoxMorningSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            if let morningSummary, !morningSummary.isEmpty {
                section("CONTINUITY") {
                    NoxMorningSummaryBanner(summary: morningSummary)
                }
            }

            if !snapshot.resurfacingNotes.isEmpty {
                section("RESURFACING") {
                    ForEach(snapshot.resurfacingNotes, id: \.self) { note in
                        Text(note)
                            .font(NoxTypography.caption)
                            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !snapshot.emergingPatterns.isEmpty {
                section("EMERGING PATTERNS") {
                    ForEach(snapshot.emergingPatterns) { pattern in
                        emergingRow(pattern)
                    }
                }
            }

            if !snapshot.semanticArcs.isEmpty {
                section("SEMANTIC ARCS") {
                    ForEach(snapshot.semanticArcs) { arc in
                        NoxSemanticArcCard(arc: arc)
                    }
                }
            }

            if !snapshot.activeThreads.isEmpty {
                section("ACTIVE THREADS") {
                    ForEach(snapshot.activeThreads) { thread in
                        NoxContinuityThreadCard(thread: thread)
                    }
                }
            }

            if !snapshot.reflections.isEmpty {
                section("REFLECTIONS") {
                    ForEach(snapshot.reflections) { reflection in
                        reflectionRow(reflection)
                    }
                }
            }

            if !snapshot.behavioralRhythms.isEmpty {
                section("BEHAVIORAL RHYTHMS") {
                    ForEach(snapshot.behavioralRhythms) { rhythm in
                        NoxBehavioralRhythmCard(entity: rhythm)
                    }
                }
            }

            if !snapshot.longHorizonNarratives.isEmpty {
                section("LONG-HORIZON MEMORY") {
                    ForEach(snapshot.longHorizonNarratives) { narrative in
                        narrativeRow(narrative)
                    }
                }
            }

            if !snapshot.eraCandidates.isEmpty {
                section("ERA CANDIDATES") {
                    NoxEraSurface(candidates: snapshot.eraCandidates)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(title)
                .font(NoxTypography.sectionLabel)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .tracking(0.6)
            content()
        }
    }

    private func emergingRow(_ pattern: NoxEmergingMemoryObservation) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            Text(pattern.title)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
            if let detail = pattern.detail {
                Text(detail)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(roundedCard)
    }

    private func reflectionRow(_ reflection: NoxReflectionCandidate) -> some View {
        Text(reflection.text)
            .font(NoxTypography.body)
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .padding(NoxSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(roundedCard)
    }

    private func narrativeRow(_ narrative: NoxLongHorizonNarrative) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            Text(narrative.horizonLabel)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            Text(narrative.summary)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(roundedCard)
    }

    private var roundedCard: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
    }
}
