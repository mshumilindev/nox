import SwiftUI

struct NoxPatternsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    private var snapshot: NoxLongHorizonSnapshot {
        environment.longHorizonSnapshot
    }

    private var memoryEvolution: NoxMemoryEvolutionSnapshot {
        snapshot.memoryEvolution
    }

    private var showsTemporalContinuity: Bool {
        memoryEvolution.temporalCoherenceLine != nil
            || !memoryEvolution.longHorizonStructures.isEmpty
            || !memoryEvolution.identityInsights.isEmpty
    }

    var body: some View {
        NoxSurfacePage {
            if snapshot.emergingPatterns.isEmpty
                && snapshot.semanticArcs.isEmpty
                && snapshot.behavioralRhythms.isEmpty
                && snapshot.behavioralSignatures.isEmpty
                && snapshot.behavioralDrift == nil {
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
                                NoxSemanticArcCard(
                                    arc: arc,
                                    evolution: memoryEvolution
                                )
                            }
                        }
                    }
                }

                if snapshot.behavioralDrift != nil || !snapshot.behavioralSignatures.isEmpty {
                    NoxCollapsibleSection(title: "Continuity shapes", defaultExpanded: false) {
                        if let drift = snapshot.behavioralDrift {
                            NoxFixedLineText(
                                text: drift.detail,
                                color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                            )
                            .noxSurface(.soft)
                        }
                        ForEach(snapshot.behavioralSignatures) { signature in
                            NoxFixedLineText(
                                text: signature.detail,
                                color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                            )
                            .frame(minHeight: NoxSurfaceLayout.arcCardMinHeight, alignment: .topLeading)
                            .noxSurface(.standard)
                        }
                    }
                }

                if !snapshot.lifeStructureCandidates.isEmpty {
                    NoxCollapsibleSection(title: "Life-shaped periods", defaultExpanded: false) {
                        ForEach(snapshot.lifeStructureCandidates) { structure in
                            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                                Text(structure.label)
                                    .font(NoxTypography.continuityDetail)
                                NoxFixedLineText(
                                    text: structure.detail,
                                    color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                                )
                            }
                            .noxSurface(.soft)
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

                if let eraLine = NoxTemporalMemoryRowPresenter.eraObservation(for: memoryEvolution) {
                    NoxMemoryEraObservationView(line: eraLine)
                }

                if showsTemporalContinuity {
                    NoxCollapsibleSection(title: "Temporal continuity", defaultExpanded: false) {
                        if let line = memoryEvolution.temporalCoherenceLine {
                            NoxFixedLineText(
                                text: line,
                                color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                            )
                            .noxSurface(.soft)
                        }
                        ForEach(memoryEvolution.longHorizonStructures, id: \.self) { structure in
                            NoxFixedLineText(
                                text: structure,
                                color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                            )
                            .noxSurface(.standard)
                        }
                        ForEach(memoryEvolution.identityInsights, id: \.line) { insight in
                            NoxFixedLineText(
                                text: insight.line,
                                color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
                            )
                            .noxSurface(.standard)
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
