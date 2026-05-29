import SwiftUI

/// Warm sun glow in the upper-left interior for the day sky. A soft radial bloom
/// plus a small bright core and a faint diagonal light wash, giving a glassy,
/// sunlit read. Faded by the caller with `opacity(sunVisibility)`.
struct OrbySunGlowView: View {
  var diameter: CGFloat

  /// Upper-left sun position (unit point within the orb).
  private let sunCenter = UnitPoint(x: 0.28, y: 0.26)

  var body: some View {
    ZStack {
      // Broad warm bloom.
      RadialGradient(
        colors: [
          Color(red: 1.0, green: 0.97, blue: 0.86).opacity(0.85),
          Color(red: 1.0, green: 0.93, blue: 0.74).opacity(0.32),
          Color.clear
        ],
        center: sunCenter,
        startRadius: 1,
        endRadius: diameter * 0.5
      )

      // Small bright sun core.
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color.white.opacity(0.95),
              Color(red: 1.0, green: 0.95, blue: 0.82).opacity(0.0)
            ],
            center: .center,
            startRadius: 0.5,
            endRadius: diameter * 0.10
          )
        )
        .frame(width: diameter * 0.20, height: diameter * 0.20)
        .position(x: diameter * sunCenter.x, y: diameter * sunCenter.y)

      // Faint diagonal light wash sweeping down-right from the sun.
      LinearGradient(
        colors: [
          Color(red: 1.0, green: 0.96, blue: 0.84).opacity(0.18),
          Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
    .frame(width: diameter, height: diameter)
  }
}
