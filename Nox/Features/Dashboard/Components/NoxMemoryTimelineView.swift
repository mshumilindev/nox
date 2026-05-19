import SwiftUI

struct NoxMemoryTimelineView: View {
    let blocks: [NoxTimelineBlockItem]
    let emergence: NoxMemoryEmergence
    let density: Double
    var dayOverview: String?
    var presence: NoxPresenceState = .quiet

    @State private var ambientGlow = false

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            sectionHeader("MEMORY")

            if let dayOverview, !dayOverview.isEmpty {
                Text(dayOverview)
                    .font(NoxTypography.body)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if blocks.isEmpty {
                emergenceState
            } else {
                VStack(alignment: .leading, spacing: NoxSpacing.md) {
                    ForEach(blocks) { block in
                        memoryRow(block)
                    }
                }
                .padding(NoxSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .opacity(0.9 + density * 0.1)
            }
        }
    }

    private var emergenceState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.accent.opacity(
                    (ambientGlow ? 0.06 : 0.025) * (0.6 + emergence.ambientDensity * 0.4)
                ))
                .animation(
                    .easeInOut(duration: 4.5).repeatForever(autoreverses: true),
                    value: ambientGlow
                )

            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                Text(emergence.title)
                    .font(NoxTypography.body)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

                if !emergence.detail.isEmpty {
                    Text(emergence.detail)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let windowLine = emergence.observationWindowLine {
                    Text(windowLine)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.85))
                }

                NoxPhilosophySurface(presence: presence, style: .emergence, showsLocalNote: false)
                    .padding(.top, NoxSpacing.sm)
            }
            .padding(NoxSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(cardBackground)
        .opacity(0.92 + emergence.ambientDensity * 0.06)
        .onAppear { ambientGlow = true }
    }

    private func memoryRow(_ block: NoxTimelineBlockItem) -> some View {
        HStack(alignment: .top, spacing: NoxSpacing.md) {
            Image(systemName: block.markerSymbol ?? "circle")
                .font(.system(size: NoxDesignTokens.SymbolSize.md, weight: .medium))
                .foregroundStyle(markerColor(for: block))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(block.title)
                        .font(NoxTypography.actionEmphasis)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                    Spacer()
                    if let durationText = block.durationText {
                        Text(durationText)
                            .font(NoxTypography.caption)
                            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                    }
                }

                if let subtitle = block.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let detail = block.detailLine, !detail.isEmpty {
                    Text(detail)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func markerColor(for block: NoxTimelineBlockItem) -> Color {
        switch block.kind {
        case .continuityThread:
            return NoxDesignTokens.ColorRole.accent
        case .semanticSpan:
            return NoxDesignTokens.ColorRole.accent
        case .focusBlock(let focus):
            switch focus.kind {
            case .deepWork, .focused:
                return NoxDesignTokens.ColorRole.accent
            case .fragmented:
                return NoxDesignTokens.ColorRole.presenceActive
            }
        case .interruption:
            return NoxDesignTokens.ColorRole.textSecondary
        default:
            return NoxDesignTokens.ColorRole.presenceMuted
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.secondary))
            .overlay {
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(NoxDesignTokens.Opacity.divider))
            }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(NoxTypography.sectionLabel)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            .tracking(0.6)
    }
}
