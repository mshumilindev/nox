import SwiftUI

/// Clear daytime sky inside the orb — a smooth blue gradient, deeper at the top,
/// brightening toward the horizon. Deliberately cloudless. Faded in by the
/// caller via `opacity(blend)`. Clipped to the circle by its host.
struct OrbyDaySkyView: View {
  /// 0…1 day strength (used for subtle internal richness; host also fades us).
  var blend: CGFloat
  var diameter: CGFloat

  var body: some View {
    let b = min(max(blend, 0), 1)
    ZStack {
      // Core sky gradient: zenith blue → soft pale horizon.
      LinearGradient(
        colors: [
          Color(red: 0.26, green: 0.52, blue: 0.86),
          Color(red: 0.42, green: 0.66, blue: 0.92),
          Color(red: 0.68, green: 0.82, blue: 0.97)
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      // Gentle atmospheric brightening toward the lower-right (sun-side haze).
      RadialGradient(
        colors: [
          Color(red: 0.86, green: 0.92, blue: 1.0).opacity(0.45 * Double(b)),
          Color.clear
        ],
        center: UnitPoint(x: 0.30, y: 0.24),
        startRadius: 2,
        endRadius: diameter * 0.62
      )
    }
    .frame(width: diameter, height: diameter)
  }
}
