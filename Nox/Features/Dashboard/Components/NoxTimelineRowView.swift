import SwiftUI

struct NoxTimelineRowView: View {
  let block: NoxTimelineBlockItem
  let isFirst: Bool
  let isLast: Bool

  private var presentation: NoxTimelineRowPresentation {
    block.presentation ?? .active
  }

  var body: some View {
    HStack(alignment: .top, spacing: NoxSpacing.md) {
      timelineMarker
        .frame(height: NoxTimelineMarkerLayout.rowHeight)

      fragmentBody
        .frame(height: NoxTimelineMarkerLayout.rowHeight, alignment: .topLeading)
    }
  }

  private var fragmentBody: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
      HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
        Text(block.title)
          .font(NoxTypography.continuityDetail)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(presentation.titleOpacity))
          .lineLimit(1)
          .layoutPriority(1)

        if let stamp = block.durationText, !stamp.isEmpty {
          Text(stamp)
            .font(NoxTypography.timelineStamp)
            .foregroundStyle(
              NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.metadataOpacity * 0.85)
            )
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
      }
      .frame(height: NoxTimelineMarkerLayout.titleLineHeight, alignment: .topLeading)

      NoxFixedLineText(
        text: block.subtitle,
        color: NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.metadataOpacity)
      )
      NoxFixedLineText(
        text: block.detailLine,
        color: NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity)
      )
      NoxFixedLineText(
        text: presentation.relationLine,
        color: NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity * 0.92)
      )
    }
    .frame(minHeight: NoxSurfaceLayout.timelineFragmentMinHeight, alignment: .topLeading)
    .padding(.top, NoxTimelineMarkerLayout.rowVerticalPadding)
    .padding(.bottom, NoxTimelineMarkerLayout.rowVerticalPadding)
  }

  private var timelineMarker: some View {
    let lineColor = NoxDesignTokens.ColorRole.border.opacity(0.14 * presentation.iconOpacity)
    let dotY = NoxTimelineMarkerLayout.dotCenterY
    let iconSize = NoxTimelineMarkerLayout.dotDiameter + 4
    return ZStack(alignment: .top) {
      Canvas { context, size in
        let x = size.width / 2
        let railHalf = iconSize / 2
        var path = Path()
        if !isFirst {
          path.move(to: CGPoint(x: x, y: 0))
          path.addLine(to: CGPoint(x: x, y: dotY - railHalf))
        }
        if !isLast {
          path.move(to: CGPoint(x: x, y: dotY + railHalf))
          path.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.stroke(path, with: .color(lineColor), lineWidth: 1)
      }

      NoxIcon(
        systemName: NoxTimelineSymbol.name(for: block),
        role: .inline,
        tint: markerColor.opacity(presentation.iconOpacity)
      )
      .frame(width: iconSize, height: iconSize)
      .position(x: NoxTimelineMarkerLayout.railWidth / 2, y: dotY)
    }
    .frame(width: NoxTimelineMarkerLayout.railWidth)
  }

  private var markerColor: Color {
    switch block.kind {
    case .continuityThread, .semanticSpan, .resurfacingMemory:
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
