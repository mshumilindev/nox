import SwiftUI

struct NoxUnifiedSignalGraphView: View {
    let snapshot: NoxObservatorySnapshot
    let series: [NoxObservatorySignalSeries]
    @State private var hoverLocation: CGPoint?
    @State private var hoverIndex: Int?
    @State private var activeSignalID: String?

    private var visibleSeries: [NoxObservatorySignalSeries] {
        series.filter(\.isVisible)
    }

    private var graphLines: [NoxObservatoryGraphLine] {
        NoxObservatoryGraphLine.collapsed(from: visibleSeries)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                graphitePanel

                Canvas { context, size in
                    drawGrid(context: &context, size: size)
                    drawSeries(context: &context, size: size)
                    drawHover(context: &context, size: size)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHover(location: value.location, size: proxy.size)
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.16)) {
                                hoverLocation = nil
                                hoverIndex = nil
                                activeSignalID = nil
                            }
                        }
                )

                if let hoverIndex, let hoverLocation {
                    tooltip(index: hoverIndex)
                        .position(tooltipPosition(for: hoverLocation, size: proxy.size))
                        .transition(.opacity)
                }
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.16), lineWidth: 0.5)
        )
        .accessibilityLabel("Unified observatory signal graph")
    }

    private var graphitePanel: some View {
        ZStack {
            LinearGradient(
                colors: [
                    NoxDesignTokens.ColorRole.canvas.opacity(0.74),
                    NoxDesignTokens.ColorRole.surface.opacity(0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    NoxObservatorySignal.recovery.color.opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
            RadialGradient(
                colors: [
                    NoxObservatorySignal.focusContinuity.color.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 12,
                endRadius: 260
            )
        }
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let horizontalLines = 4
        let verticalLines = 6
        var path = Path()
        for index in 1..<horizontalLines {
            let y = size.height * CGFloat(index) / CGFloat(horizontalLines)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        for index in 1..<verticalLines {
            let x = size.width * CGFloat(index) / CGFloat(verticalLines)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.stroke(path, with: .color(NoxDesignTokens.ColorRole.border.opacity(0.10)), lineWidth: 0.5)
    }

    private func drawSeries(context: inout GraphicsContext, size: CGSize) {
        for line in graphLines {
            let isActive = activeSignalID == nil || activeSignalID == line.id
            let opacity = isActive ? (activeSignalID == line.id ? 0.98 : 0.82) : 0.24
            let width = activeSignalID == line.id ? 1.9 : 1.15
            context.stroke(
                path(for: line, size: size),
                with: .color(line.color.opacity(opacity)),
                lineWidth: width
            )
        }
    }

    private func drawHover(context: inout GraphicsContext, size: CGSize) {
        guard let hoverLocation, hoverLocation.x >= 0, hoverLocation.x <= size.width else { return }
        var guide = Path()
        guide.move(to: CGPoint(x: hoverLocation.x, y: 0))
        guide.addLine(to: CGPoint(x: hoverLocation.x, y: size.height))
        context.stroke(guide, with: .color(NoxDesignTokens.ColorRole.textSecondary.opacity(0.18)), lineWidth: 0.6)
    }

    private func path(for series: NoxObservatoryGraphLine, size: CGSize) -> Path {
        let values = series.values
        guard values.count > 1 else { return Path() }
        let inset: CGFloat = 14
        let width = max(1, size.width - inset * 2)
        let height = max(1, size.height - inset * 2)
        let points = values.enumerated().map { index, point in
            CGPoint(
                x: inset + width * CGFloat(index) / CGFloat(max(1, values.count - 1)),
                y: inset + height * CGFloat(1 - displayY(point.value))
            )
        }

        var path = Path()
        path.move(to: points[0])
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let controlDistance = (current.x - previous.x) * 0.46
            path.addCurve(
                to: current,
                control1: CGPoint(x: previous.x + controlDistance, y: previous.y),
                control2: CGPoint(x: current.x - controlDistance, y: current.y)
            )
        }
        return path
    }

    private func updateHover(location: CGPoint, size: CGSize) {
        guard let first = graphLines.first, first.values.count > 1 else { return }
        let inset: CGFloat = 14
        let normalizedX = min(max((location.x - inset) / max(1, size.width - inset * 2), 0), 1)
        let index = Int((normalizedX * CGFloat(first.values.count - 1)).rounded())
        let clampedIndex = min(max(index, 0), first.values.count - 1)
        let dominant = graphLines
            .compactMap { series -> (String, Double)? in
                guard series.values.indices.contains(clampedIndex) else { return nil }
                return (series.id, series.values[clampedIndex].value)
            }
            .max { $0.1 < $1.1 }?
            .0

        hoverLocation = location
        hoverIndex = clampedIndex
        activeSignalID = dominant
    }

    private func tooltip(index: Int) -> some View {
        let dominant = graphLines
            .compactMap { series -> (NoxObservatoryGraphLine, Double)? in
                guard series.values.indices.contains(index) else { return nil }
                return (series, series.values[index].value)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
        let timestamp = graphLines.first?.values[safe: index]?.timestamp ?? snapshot.start

        return VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            Text(timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(NoxTypography.timelineStamp)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
            ForEach(Array(dominant), id: \.0.id) { item in
                HStack(spacing: NoxSpacing.xs) {
                    Circle()
                        .fill(item.0.color)
                        .frame(width: 5, height: 5)
                    Text(item.0.title)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.82))
                    Spacer(minLength: 0)
                    Text("\(Int((item.1 * 100).rounded()))")
                        .font(NoxTypography.timelineStamp)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
                }
            }
            if snapshot.maturity == .gathering {
                Text("Continuity note withheld.")
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.50))
            }
        }
        .padding(NoxSpacing.sm)
        .frame(width: 190, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.canvas.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                        .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.18), lineWidth: 0.5)
                )
        )
    }

    private func tooltipPosition(for point: CGPoint, size: CGSize) -> CGPoint {
        let x = point.x > size.width - 220 ? point.x - 106 : point.x + 106
        let y = point.y < 82 ? 92 : max(86, point.y - 22)
        return CGPoint(x: x, y: min(size.height - 86, y))
    }

    private func displayY(_ value: Double) -> Double {
        0.08 + min(max(value, 0), 1) * 0.84
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
