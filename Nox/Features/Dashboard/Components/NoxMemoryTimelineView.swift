import SwiftUI

struct NoxMemoryTimelineView: View {
  let period: NoxMemoryPeriod
  let sections: [NoxTimelineSection]
  let stats: NoxMemoryDayStats
  let emergence: NoxMemoryEmergence
  let density: Double
  var dayOverview: String?
  var presence: NoxPresenceState = .quiet

  private var isEmpty: Bool {
    sections.allSatisfy { $0.items.isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.md) {
      Text("Timeline")
        .noxSectionLabel()

      if let dayOverview, !dayOverview.isEmpty {
        Text(dayOverview)
          .font(NoxTypography.body)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom, NoxSpacing.xs)
      }

      if isEmpty {
        emptyState
      } else {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
          ForEach(sections) { section in
            timelineSection(section)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var emptyState: some View {
    if period == .today {
      emergenceState
    } else {
      historicalEmptyState
    }
  }

  private func timelineSection(_ section: NoxTimelineSection) -> some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(section.layer.title)
        .font(NoxTypography.sectionLabel)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
        .textCase(.uppercase)

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, block in
          memoryFragment(
            block,
            isFirst: index == 0,
            isLast: index == section.items.count - 1
          )
        }
      }
    }
  }

  private var emergenceState: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(emergence.title)
        .font(NoxTypography.body)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      if !emergence.detail.isEmpty {
        Text(emergence.detail)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }

      if let windowLine = emergence.observationWindowLine {
        Text(windowLine)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
      }
    }
    .noxSurface(.inset)
  }

  private var historicalEmptyState: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(NoxMemoryPeriodEmptyCopy.title(period: period, stats: stats))
        .font(NoxTypography.body)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
      Text(NoxMemoryPeriodEmptyCopy.detail(period: period))
        .noxMetadata()
        .fixedSize(horizontal: false, vertical: true)
    }
    .noxSurface(.inset)
  }

  private func memoryFragment(
    _ block: NoxTimelineBlockItem,
    isFirst: Bool,
    isLast: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: NoxSpacing.md) {
      timelineMarker(for: block, isFirst: isFirst, isLast: isLast)

      VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
          Text(block.title)
            .font(NoxTypography.continuityDetail)
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
            .lineLimit(1)
            .layoutPriority(1)

          if let durationText = block.durationText {
            Text(durationText)
              .font(NoxTypography.timelineStamp)
              .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.45))
              .lineLimit(1)
              .fixedSize(horizontal: true, vertical: false)
          }
        }

        NoxFixedLineText(text: block.subtitle)
        NoxFixedLineText(
          text: block.detailLine,
          color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.48)
        )
      }
      .frame(minHeight: NoxSurfaceLayout.timelineFragmentMinHeight, alignment: .topLeading)
      .padding(.vertical, NoxSpacing.sm)
    }
  }

  private func timelineMarker(
    for block: NoxTimelineBlockItem,
    isFirst: Bool,
    isLast: Bool
  ) -> some View {
    let lineColor = NoxDesignTokens.ColorRole.border.opacity(0.14)
    return VStack(spacing: 0) {
      Rectangle()
        .fill(lineColor)
        .frame(width: 1)
        .frame(maxHeight: .infinity)
        .opacity(isFirst ? 0 : 1)

      Circle()
        .fill(markerColor(for: block).opacity(0.75))
        .frame(width: 5, height: 5)

      Rectangle()
        .fill(lineColor)
        .frame(width: 1)
        .frame(maxHeight: .infinity)
        .opacity(isLast ? 0 : 1)
    }
    .frame(width: 12)
  }

  private func markerColor(for block: NoxTimelineBlockItem) -> Color {
    switch block.kind {
    case .continuityThread, .semanticSpan:
      NoxDesignTokens.ColorRole.accent
    case .focusBlock(let focus):
      switch focus.kind {
      case .deepWork, .focused:
        NoxDesignTokens.ColorRole.accent
      case .fragmented:
        NoxDesignTokens.ColorRole.presenceActive
      }
    case .interruption:
      NoxDesignTokens.ColorRole.textSecondary
    default:
      NoxDesignTokens.ColorRole.presenceMuted
    }
  }
}
