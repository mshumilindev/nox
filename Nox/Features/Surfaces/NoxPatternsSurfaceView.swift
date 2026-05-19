import SwiftUI

struct NoxPatternsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    private var snapshot: NoxLongHorizonSnapshot {
        environment.longHorizonSnapshot
    }

    var body: some View {
        NoxSurfacePage {
            if snapshot.emergingPatterns.isEmpty
                && snapshot.semanticArcs.isEmpty
                && snapshot.behavioralRhythms.isEmpty {
                emptyPatterns
            } else {
                if !snapshot.emergingPatterns.isEmpty {
                    patternGroup(title: "Emerging", symbol: "leaf") {
                        ForEach(snapshot.emergingPatterns) { pattern in
                            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                                Text(pattern.title)
                                    .font(NoxTypography.continuityDetail)
                                    .lineLimit(1)
                                NoxFixedLineText(
                                    text: pattern.detail,
                                    color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                                )
                            }
                            .frame(minHeight: NoxSurfaceLayout.arcCardMinHeight, alignment: .topLeading)
                            .noxSurface(.standard)
                        }
                    }
                }

                if !snapshot.semanticArcs.isEmpty {
                    NoxCollapsibleSection(
                        title: "Semantic arcs",
                        subtitle: "\(snapshot.semanticArcs.count) arcs",
                        defaultExpanded: environment.preferences.surfaceDensity.showsDetailByDefault
                    ) {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: NoxSpacing.md)],
                            spacing: NoxSpacing.cardStack
                        ) {
                            ForEach(snapshot.semanticArcs) { arc in
                                NoxSemanticArcCard(arc: arc)
                            }
                        }
                    }
                }

                if !snapshot.behavioralRhythms.isEmpty {
                    NoxCollapsibleSection(title: "Rhythms", defaultExpanded: false) {
                        ForEach(snapshot.behavioralRhythms) { rhythm in
                            NoxBehavioralRhythmCard(entity: rhythm)
                        }
                    }
                }

                if !snapshot.connectorCadencePatterns.isEmpty {
                    NoxCollapsibleSection(title: "Cadence", defaultExpanded: false) {
                        ForEach(snapshot.connectorCadencePatterns) { pattern in
                            Text(pattern.label)
                                .font(NoxTypography.continuityDetail)
                                .lineLimit(2)
                                .frame(minHeight: NoxSurfaceLayout.arcCardMinHeight, alignment: .topLeading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .noxSurface(.standard)
                        }
                    }
                }

                if !snapshot.connectorEnrichmentNotes.isEmpty {
                    NoxCollapsibleSection(title: "Continuity enrichment", defaultExpanded: false) {
                        ForEach(snapshot.connectorEnrichmentNotes, id: \.self) { note in
                            Text(note)
                                .noxMetadata()
                                .noxSurface(.soft)
                        }
                    }
                }
            }
        }
    }

    private var emptyPatterns: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(
                title: "Patterns",
                symbol: "square.grid.3x3",
                subtitle: "Arcs and rhythms gather as activity repeats."
            )
            Text("Patterns appear as activity repeats across sessions.")
                .font(NoxTypography.reflectionSoft)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
                .noxSurface(.inset, padding: NoxMaterials.cardPaddingLoose)
        }
    }

    @ViewBuilder
    private func patternGroup<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: title, symbol: symbol)
            VStack(alignment: .leading, spacing: NoxSpacing.cardStack) {
                content()
            }
        }
    }
}
