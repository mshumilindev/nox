import SwiftUI

/// Deep window mode — pattern topology (arcs, emerging signals, rhythms).
struct NoxDeepPatternsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    private var snapshot: NoxLongHorizonSnapshot {
        environment.longHorizonSnapshot
    }

    var body: some View {
        NoxSurfacePage {
            header

            if !snapshot.emergingPatterns.isEmpty {
                emergingSection
            }

            if !snapshot.semanticArcs.isEmpty {
                arcTopology
            }

            if !snapshot.behavioralRhythms.isEmpty {
                rhythmsSection
            }

            if isSparse {
                sparseState
            }
        }
    }

    private var isSparse: Bool {
        snapshot.emergingPatterns.isEmpty
            && snapshot.semanticArcs.isEmpty
            && snapshot.behavioralRhythms.isEmpty
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text("Pattern layer")
                .noxPageTitle()
            Text("Semantic arcs and rhythms gathered locally — not scores or goals.")
                .font(NoxTypography.reflectionSoft)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emergingSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: "Emerging", symbol: "leaf")
            ForEach(snapshot.emergingPatterns) { pattern in
                VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                    Text(pattern.title)
                        .font(NoxTypography.continuityDetail)
                    if let detail = pattern.detail {
                        Text(detail)
                            .noxMetadata()
                    }
                }
                .noxSurface(.standard)
            }
        }
    }

    private var arcTopology: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: "Semantic arcs", symbol: "square.grid.3x3")
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: NoxSpacing.md),
                    GridItem(.flexible(), spacing: NoxSpacing.md)
                ],
                spacing: NoxSpacing.cardStack
            ) {
                ForEach(snapshot.semanticArcs) { arc in
                    NoxSemanticArcCard(arc: arc)
                }
            }
        }
    }

    private var rhythmsSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: "Rhythms", symbol: "waveform.path")
            ForEach(snapshot.behavioralRhythms) { rhythm in
                NoxBehavioralRhythmCard(entity: rhythm)
            }
        }
    }

    private var sparseState: some View {
        Text("Patterns appear as activity repeats across sessions. Arcs and rhythms will gather here.")
            .font(NoxTypography.reflectionSoft)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
            .noxSurface(.inset, padding: NoxMaterials.cardPaddingLoose)
    }
}
