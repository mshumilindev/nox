import SwiftUI
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

struct NoxObservatoryObservationPanel: View {
    let snapshot: NoxObservatorySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(
                title: "Observations",
                symbol: "text.magnifyingglass",
                subtitle: "What Nox noticed — when the signal is strong enough."
            )

            VStack(alignment: .leading, spacing: NoxSpacing.cardStack) {
                ForEach(snapshot.observations) { observation in
                    observationRow(observation)
                }
            }
        }
    }

    private func observationRow(_ observation: NoxObservatoryObservation) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
                severityMark(observation.severity)
                Text(observation.title)
                    .font(NoxTypography.continuity)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
                Spacer(minLength: 0)
                Text("\(Int((observation.confidence * 100).rounded()))%")
                    .font(NoxTypography.timelineStamp)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.46))
            }

            Text(observation.detail)
                .font(NoxTypography.reflectionSoft)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            if snapshot.maturity >= .tentative {
                VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                    ForEach(observation.evidence.prefix(2), id: \.self) { evidence in
                        Text(evidence)
                            .font(NoxTypography.caption)
                            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.44))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.surface.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                        .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.10), lineWidth: 0.5)
                )
        )
    }

    private func severityMark(_ severity: NoxObservatoryObservationSeverity) -> some View {
        Circle()
            .fill(color(for: severity).opacity(0.82))
            .frame(width: 6, height: 6)
    }

    private func color(for severity: NoxObservatoryObservationSeverity) -> Color {
        switch severity {
        case .note: NoxObservatorySignal.rhythmStability.color
        case .elevated: NoxObservatorySignal.coordinationLoad.color
        case .severe: NoxObservatorySignal.overloadPressure.color
        }
    }
}

struct NoxObservatoryLegendView: View {
    let series: [NoxObservatorySignalSeries]
    @Binding var hiddenSignals: Set<String>
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: NoxSpacing.sm) {
                    NoxIcon(systemName: expanded ? "chevron.down" : "chevron.right", role: .inline)
                    Text("Signal groups")
                        .noxSectionLabel()
                    Spacer(minLength: 0)
                    Text("\(NoxObservatorySignalGroup.allCases.count)")
                        .font(NoxTypography.timelineStamp)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.44))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: NoxSpacing.sm)],
                    alignment: .leading,
                    spacing: NoxSpacing.sm
                ) {
                    ForEach(NoxObservatorySignalGroup.allCases) { group in
                        signalToggle(group)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, NoxSpacing.xs)
    }

    private func signalToggle(_ group: NoxObservatorySignalGroup) -> some View {
        let ids = Set(group.signals.map(\.id))
        let hidden = ids.isSubset(of: hiddenSignals)
        return Button {
            if hidden {
                hiddenSignals.subtract(ids)
            } else {
                hiddenSignals.formUnion(ids)
            }
        } label: {
            HStack(spacing: NoxSpacing.xs) {
                Circle()
                    .fill(group.color.opacity(hidden ? 0.28 : 0.88))
                    .frame(width: 7, height: 7)
                Text(group.title)
                    .font(NoxTypography.caption)
                    .foregroundStyle(
                        hidden
                        ? NoxDesignTokens.ColorRole.textSecondary.opacity(0.34)
                        : NoxDesignTokens.ColorRole.textSecondary.opacity(0.68)
                    )
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 22)
        }
        .buttonStyle(.plain)
        .help(group.description)
    }
}
