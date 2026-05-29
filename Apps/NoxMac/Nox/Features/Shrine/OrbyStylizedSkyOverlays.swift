import SwiftUI

/// Noir grading + venetian light bands for the `noirDetective` beat. Clipped to the orb.
struct OrbyNoirGradingView: View {
  var reveal: Double
  var bandPhase: Double
  var clueOpacity: Double
  var diameter: CGFloat

  var body: some View {
    let r = min(max(reveal, 0), 1)
    ZStack {
      // Desaturate/darken toward graphite-violet.
      Color(red: 0.12, green: 0.10, blue: 0.18).opacity(0.42 * r)
      LinearGradient(
        colors: [
          Color(red: 0.30, green: 0.30, blue: 0.40).opacity(0.30 * r),
          Color(red: 0.06, green: 0.05, blue: 0.12).opacity(0.50 * r)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      // Diagonal venetian light bands (pale gray-blue), sweeping subtly.
      bands(r: r)

      // Optional tiny "clue" glint near the lower interior.
      if clueOpacity > 0.01 {
        Circle()
          .fill(Color(red: 0.82, green: 0.86, blue: 0.95))
          .frame(width: 2.6, height: 2.6)
          .shadow(color: Color.white.opacity(0.5), radius: 2)
          .position(x: diameter * 0.42, y: diameter * 0.78)
          .opacity(clueOpacity * r)
      }
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .allowsHitTesting(false)
  }

  private func bands(r: Double) -> some View {
    let sweep = CGFloat(sin(bandPhase)) * 4
    return ZStack {
      ForEach(0..<3, id: \.self) { i in
        Rectangle()
          .fill(Color(red: 0.80, green: 0.86, blue: 0.96).opacity(0.16 * r))
          .frame(width: diameter * 1.6, height: 3.2)
          .offset(y: CGFloat(i - 1) * 11 + sweep)
      }
    }
    .rotationEffect(.degrees(-32))
    .blur(radius: 0.6)
  }
}

/// A tiny black hole + nibbled star for `blackHoleNibble`. Clipped to the orb, below the face.
struct OrbyBlackHoleView: View {
  var strength: Double
  var side: CGFloat
  var starProgress: Double
  var diameter: CGFloat

  var body: some View {
    let s = min(max(strength, 0), 1)
    let center = CGPoint(x: diameter / 2 + side * 21, y: diameter / 2 + 4)
    let coreR = 5.0 * s

    // Nibbled star starts a little outward from the hole and is pulled in.
    let startPoint = CGPoint(x: center.x + side * 16, y: center.y - 10)
    let sp = CGFloat(min(max(starProgress, 0), 1))
    let starPos = CGPoint(
      x: startPoint.x + (center.x - startPoint.x) * sp,
      y: startPoint.y + (center.y - startPoint.y) * sp
    )
    let starScale = max(0, 1 - sp)

    return ZStack {
      // Faint accretion ring.
      Circle()
        .stroke(
          AngularGradient(
            colors: [
              Color(red: 0.55, green: 0.4, blue: 0.95).opacity(0.5),
              Color(red: 0.3, green: 0.75, blue: 0.95).opacity(0.35),
              Color(red: 0.7, green: 0.3, blue: 0.7).opacity(0.4),
              Color(red: 0.55, green: 0.4, blue: 0.95).opacity(0.5)
            ],
            center: .center
          ),
          lineWidth: 1.4
        )
        .frame(width: coreR * 3.0, height: coreR * 3.0)
        .position(center)
        .opacity(s)

      // Nibbled star.
      Circle()
        .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
        .frame(width: 2.6, height: 2.6)
        .scaleEffect(starScale)
        .position(starPos)
        .opacity(s * Double(starScale))

      // Dark core (near-black violet, soft edge).
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color(red: 0.04, green: 0.02, blue: 0.08),
              Color(red: 0.10, green: 0.06, blue: 0.18).opacity(0.0)
            ],
            center: .center,
            startRadius: 0.5,
            endRadius: coreR * 1.8
          )
        )
        .frame(width: coreR * 3.4, height: coreR * 3.4)
        .position(center)
        .opacity(s)
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .allowsHitTesting(false)
  }
}

/// A small comet that enters from outside, crosses the sky, and exits. Drawn in the padded
/// bounds (NOT clipped to the circle) so its entry/exit tails can briefly cross the boundary.
struct OrbyCometView: View {
  var opacity: Double
  var progress: Double
  /// Full padded side length the chrome lays out (diameter + 2 × padding).
  var boundsSide: CGFloat

  var body: some View {
    let p = CGFloat(min(max(progress, 0), 1))
    let half = boundsSide / 2
    // Path from just outside the left edge to just outside the right edge, gentle arc.
    let startX = -half + 6
    let endX = boundsSide - half - 6
    let x = startX + (endX - startX) * p
    // Slight upward-then-down arc.
    let arc = sin(Double(p) * .pi) * Double(boundsSide) * 0.10
    let y = -Double(boundsSide) * 0.10 + Double(boundsSide) * 0.20 * Double(p) - arc

    return ZStack {
      // Soft tail behind the core (points back along travel direction).
      Capsule()
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.80, green: 0.88, blue: 1.0).opacity(0.0),
              Color(red: 0.86, green: 0.92, blue: 1.0).opacity(0.7)
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 20, height: 3.0)
        .blur(radius: 1.0)
        .offset(x: -11)
      // Bright core.
      Circle()
        .fill(Color.white)
        .frame(width: 3.4, height: 3.4)
        .shadow(color: Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.9), radius: 3)
    }
    .position(x: half + x, y: half + CGFloat(y))
    .frame(width: boundsSide, height: boundsSide)
    .opacity(opacity)
    .allowsHitTesting(false)
  }
}
