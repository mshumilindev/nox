import SwiftUI

/// Passive meteor streaks inside Orby's clipped internal sky (below face, above starfield).
struct OrbyAmbientMeteorLayerView: View {
  let diameter: CGFloat
  let meteors: [OrbyAmbientMeteorRenderItem]

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = diameter / 2
      for item in meteors {
        drawMeteor(item, in: &context, center: center, radius: radius)
      }
    }
    .frame(width: diameter, height: diameter)
    .allowsHitTesting(false)
  }

  private func drawMeteor(
    _ item: OrbyAmbientMeteorRenderItem,
    in context: inout GraphicsContext,
    center: CGPoint,
    radius: CGFloat
  ) {
    let head = map(item.head, center: center, radius: radius)
    let tail = map(item.tailEnd, center: center, radius: radius)
    let colors = meteorColors(item.color)

    if item.tailOpacity > 0.01 {
      var tailPath = Path()
      tailPath.move(to: tail)
      tailPath.addLine(to: head)
      context.stroke(
        tailPath,
        with: .linearGradient(
          Gradient(colors: [
            colors.tail.opacity(0),
            colors.tail.opacity(item.tailOpacity * 0.35),
            colors.core.opacity(item.tailOpacity)
          ]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: item.tailWidth, lineCap: .round)
      )
    }

    if item.headOpacity > 0.01 {
      let glowRect = CGRect(
        x: head.x - item.headSize,
        y: head.y - item.headSize,
        width: item.headSize * 2,
        height: item.headSize * 2
      )
      context.fill(
        Path(ellipseIn: glowRect),
        with: .color(colors.core.opacity(item.headOpacity * 0.45))
      )
      let coreRect = CGRect(
        x: head.x - item.headSize * 0.45,
        y: head.y - item.headSize * 0.45,
        width: item.headSize * 0.9,
        height: item.headSize * 0.9
      )
      context.fill(
        Path(ellipseIn: coreRect),
        with: .color(colors.core.opacity(item.headOpacity))
      )
    }
  }

  private func map(_ point: CGPoint, center: CGPoint, radius: CGFloat) -> CGPoint {
    CGPoint(x: center.x + point.x * radius, y: center.y + point.y * radius)
  }

  private func meteorColors(_ color: OrbyMeteorColor) -> (core: Color, tail: Color) {
    switch color {
    case .paleLavender:
      return (Color(red: 0.94, green: 0.93, blue: 1.0), Color(red: 0.78, green: 0.74, blue: 0.96))
    case .paleCyan:
      return (Color(red: 0.88, green: 0.97, blue: 1.0), Color(red: 0.62, green: 0.86, blue: 0.96))
    case .paleRose:
      return (Color(red: 1.0, green: 0.94, blue: 0.97), Color(red: 0.88, green: 0.76, blue: 0.86))
    }
  }
}
