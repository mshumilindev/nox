import SwiftUI

/// Tiny twinkling stars inside the orb — clipped to circle; deterministic layout.
struct OrbyStarfieldView: View {
  let diameter: CGFloat
  let config: OrbyCosmicMaterialConfig
  let stars: [OrbyCosmicStar]

  init(
    diameter: CGFloat,
    config: OrbyCosmicMaterialConfig,
    stars: [OrbyCosmicStar] = OrbyCosmicStarCatalog.shared
  ) {
    self.diameter = diameter
    self.config = config
    self.stars = stars
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate
      Canvas { context, size in
        let clip = Path(ellipseIn: CGRect(origin: .zero, size: size))
        context.clip(to: clip)

        for star in stars {
          draw(star, at: time, in: &context, size: size)
        }
      }
    }
    .frame(width: diameter, height: diameter)
    .allowsHitTesting(false)
  }

  private func draw(
    _ star: OrbyCosmicStar,
    at time: TimeInterval,
    in context: inout GraphicsContext,
    size: CGSize
  ) {
    let opacity = star.opacity(at: time, config: config)
    guard opacity > 0.04 else { return }

    let point = star.position(in: size)
    // Stars tighten to ~20% smaller as Orby sleeps — crisper, sharper points.
    let r = star.radius * (1 - 0.20 * config.sleepDepth)
    let colorIntensity = coloredIntensity(for: star.color)
    let rgb = star.color.components(intensity: colorIntensity)
    let fill = Color(
      red: rgb.red,
      green: rgb.green,
      blue: rgb.blue,
      opacity: opacity
    )

    switch star.style {
    case .dot:
      let rect = CGRect(
        x: point.x - r,
        y: point.y - r,
        width: r * 2,
        height: r * 2
      )
      context.fill(Path(ellipseIn: rect), with: .color(fill))
      if r >= 1.4, opacity > 0.42 {
        let glow = CGRect(
          x: point.x - r * 1.6,
          y: point.y - r * 1.6,
          width: r * 3.2,
          height: r * 3.2
        )
        context.fill(
          Path(ellipseIn: glow),
          with: .color(fill.opacity(opacity * 0.22))
        )
      }
    case .glint:
      drawGlint(at: point, radius: r, color: fill, in: &context)
    }
  }

  private func drawGlint(
    at point: CGPoint,
    radius: CGFloat,
    color: Color,
    in context: inout GraphicsContext
  ) {
    let arm = radius * 1.35
    var h = Path()
    h.move(to: CGPoint(x: point.x - arm, y: point.y))
    h.addLine(to: CGPoint(x: point.x + arm, y: point.y))
    var v = Path()
    v.move(to: CGPoint(x: point.x, y: point.y - arm))
    v.addLine(to: CGPoint(x: point.x, y: point.y + arm))
    context.stroke(h, with: .color(color), lineWidth: max(0.55, radius * 0.38))
    context.stroke(v, with: .color(color), lineWidth: max(0.55, radius * 0.38))
    let core = CGRect(
      x: point.x - radius * 0.55,
      y: point.y - radius * 0.55,
      width: radius * 1.1,
      height: radius * 1.1
    )
    context.fill(Path(ellipseIn: core), with: .color(color))
  }

  private func coloredIntensity(for color: OrbyCosmicStarColor) -> CGFloat {
    switch color {
    case .lavenderWhite:
      return 1
    case .paleBlue, .paleRose:
      return config.coloredStarIntensity
    }
  }
}
