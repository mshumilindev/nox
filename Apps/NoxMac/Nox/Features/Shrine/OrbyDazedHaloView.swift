import SwiftUI

/// Four cartoon yellow stars orbiting Orby’s head (pseudo-3D front/back) during post-drag dazed.
struct OrbyDazedHaloView: View {
  let opacity: Double
  var layer: Layer = .combined

  enum Layer {
    case back
    case front
    case combined
  }

  var body: some View {
    Group {
      if opacity > 0.02 {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
          let time = timeline.date.timeIntervalSinceReferenceDate
          let baseAngle = time / OrbyDizzyStarsGeometry.orbitPeriodSeconds * 2 * .pi
          ZStack {
            ForEach(0..<4, id: \.self) { index in
              starView(index: index, baseAngle: baseAngle)
            }
          }
          .frame(width: OrbyDizzyStarsGeometry.canvasSize, height: OrbyDizzyStarsGeometry.canvasSize)
        }
      }
    }
  }

  @ViewBuilder
  private func starView(index: Int, baseAngle: Double) -> some View {
    let angle = baseAngle + Double(index) * (.pi / 2)
    let sinA = sin(angle)
    let cosA = cos(angle)
    let isFront = sinA > 0.08
    let isBack = sinA < -0.08
    let center = OrbyDizzyStarsGeometry.orbCenter

    if layer == .back, !isBack { EmptyView() }
    else if layer == .front, !isFront { EmptyView() }
    else {
      let cx = center.x + CGFloat(cosA) * OrbyDizzyStarsGeometry.orbitRadiusX
      let cy = center.y + OrbyDizzyStarsGeometry.orbitCenterYOffset + CGFloat(sinA) * OrbyDizzyStarsGeometry.orbitRadiusY
      let size: CGFloat = isFront
        ? OrbyDizzyStarsGeometry.starSizeFront
        : (isBack ? OrbyDizzyStarsGeometry.starSizeBack : OrbyDizzyStarsGeometry.starSizeMid)
      let starOpacity = opacity * (isFront ? 0.95 : (isBack ? 0.42 : 0.7))

      OrbyCartoonStarShape()
        .fill(
          LinearGradient(
            colors: [
              Color(red: 1.0, green: 0.94, blue: 0.45),
              Color(red: 1.0, green: 0.78, blue: 0.22)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: size, height: size)
        .shadow(color: Color.orange.opacity(0.35), radius: 0.5, y: 0.5)
        .position(x: cx, y: cy)
        .opacity(starOpacity)
        .zIndex(isFront ? 20 : (isBack ? -1 : 5))
    }
  }
}

/// Simple 4-point cartoon star.
struct OrbyCartoonStarShape: Shape {
  func path(in rect: CGRect) -> Path {
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) * 0.48
    let inner = outer * 0.42
    var path = Path()
    for i in 0..<8 {
      let a = Double(i) * .pi / 4 - .pi / 2
      let r = i.isMultiple(of: 2) ? outer : inner
      let p = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
      if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    path.closeSubpath()
    return path
  }
}
