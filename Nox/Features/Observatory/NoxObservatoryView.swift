import SwiftUI

struct NoxObservatoryView: View {
    var body: some View {
        NoxObservatorySurface()
    }
}

struct NoxObservatorySurface: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var hiddenSignals = Set<String>()

    private var visibleSeries: [NoxObservatorySignalSeries] {
        environment.observatorySnapshot.series.map { series in
            var updated = series
            updated.isVisible = !hiddenSignals.contains(series.id)
            return updated
        }
    }

    var body: some View {
        NoxSurfacePage {
            NoxObservatoryHeader(
                snapshot: environment.observatorySnapshot,
                selectedRange: environment.observatoryRange,
                onRangeChange: environment.setObservatoryRange
            )

            NoxUnifiedSignalGraphView(
                snapshot: environment.observatorySnapshot,
                series: visibleSeries
            )

            NoxObservatoryLegendView(
                series: environment.observatorySnapshot.series,
                hiddenSignals: $hiddenSignals
            )

            NoxObservatoryObservationPanel(snapshot: environment.observatorySnapshot)
        }
        .task {
            await MainActor.run {
                environment.setObservatoryRange(environment.observatoryRange)
            }
        }
    }
}

struct NoxObservatoryHeader: View {
    let snapshot: NoxObservatorySnapshot
    let selectedRange: NoxObservatoryTimeRange
    let onRangeChange: (NoxObservatoryTimeRange) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
                VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                    Text("Observatory")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))

                    Text("Local continuity signals, normalized into one long-horizon field.")
                        .font(NoxTypography.surfaceSubtitle)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: NoxSpacing.sm)

                Text(snapshot.bucketSize.label)
                    .font(NoxTypography.timelineStamp)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.52))
            }

            HStack(spacing: NoxSpacing.md) {
                NoxObservatoryRangePicker(
                    selection: selectedRange,
                    onChange: onRangeChange
                )

                Spacer(minLength: 0)

                Text(snapshot.maturity.copy)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.58))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 210, alignment: .trailing)
            }
        }
    }
}

struct NoxObservatoryRangePicker: View {
    let selection: NoxObservatoryTimeRange
    let onChange: (NoxObservatoryTimeRange) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(NoxObservatoryTimeRange.allCases) { range in
                Button {
                    onChange(range)
                } label: {
                    Text(range.title)
                        .font(NoxTypography.controlLabel)
                        .foregroundStyle(
                            selection == range
                            ? NoxDesignTokens.ColorRole.textPrimary.opacity(0.9)
                            : NoxDesignTokens.ColorRole.textSecondary.opacity(0.58)
                        )
                        .frame(minWidth: 34, minHeight: 24)
                        .background {
                            if selection == range {
                                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                                    .fill(NoxDesignTokens.ColorRole.accent.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                                            .strokeBorder(NoxDesignTokens.ColorRole.accent.opacity(0.18), lineWidth: 0.5)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.surface.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                        .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.12), lineWidth: 0.5)
                )
        )
    }
}
