import SwiftUI

/// Soft internal nebula clouds clipped to the orb circle.
struct OrbyNebulaView: View {
  let diameter: CGFloat
  let config: OrbyCosmicMaterialConfig
  var driftPhase: Double = 0

  private var opacityScale: Double { Double(config.nebulaOpacity) }

  private var bandAngleDegrees: Double {
    OrbyCosmicMaterialConfig.milkyWayAngleRadians * 180 / .pi
  }

  var body: some View {
    ZStack {
      mainVioletCloud
      secondaryBlueMagentaCloud
      milkyWayBand
      milkyWayDustLane
      centerFaceFalloff
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .allowsHitTesting(false)
  }

  private var driftOffset: CGFloat {
    guard config.nebulaDriftEnabled else { return 0 }
    return CGFloat(sin(driftPhase) * 0.012 * diameter)
  }

  /// Luminous galactic band stretched diagonally across the orb — brighter spine, soft falloff.
  private var milkyWayBand: some View {
    let intensity = Double(config.milkyWayIntensity) * opacityScale
    return Ellipse()
      .fill(
        LinearGradient(
          colors: [
            Color.clear,
            Color(red: 0.62, green: 0.55, blue: 0.92).opacity(0.10 * intensity),
            Color(red: 0.82, green: 0.80, blue: 1.0).opacity(0.30 * intensity),
            Color(red: 0.70, green: 0.62, blue: 0.96).opacity(0.16 * intensity),
            Color.clear
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .frame(width: diameter * 1.34, height: diameter * 0.34)
      .blur(radius: 6)
      .rotationEffect(.degrees(bandAngleDegrees + sin(driftPhase * 0.3) * 1.5))
      .offset(x: driftOffset * 0.5, y: -diameter * 0.02)
  }

  /// Darker dust lane running just off the band spine, the way a real Milky Way photo splits.
  private var milkyWayDustLane: some View {
    let intensity = Double(config.milkyWayIntensity) * opacityScale
    return Ellipse()
      .fill(
        LinearGradient(
          colors: [
            Color.clear,
            Color(red: 0.06, green: 0.03, blue: 0.16).opacity(0.34 * intensity),
            Color.clear
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .frame(width: diameter * 1.20, height: diameter * 0.10)
      .blur(radius: 3.5)
      .rotationEffect(.degrees(bandAngleDegrees + sin(driftPhase * 0.3) * 1.5))
      .offset(x: driftOffset * 0.5, y: diameter * 0.05)
  }

  /// Main violet cloud — elongated along the galactic axis (bottom-right → top-left),
  /// thinner so it doesn't flood the orb interior, and long enough to reach the edges.
  private var mainVioletCloud: some View {
    Ellipse()
      .fill(
        RadialGradient(
          colors: [
            Color(red: 0.52, green: 0.34, blue: 0.82).opacity(0.30 * opacityScale),
            Color(red: 0.38, green: 0.22, blue: 0.62).opacity(0.18 * opacityScale),
            Color.clear
          ],
          center: .center,
          startRadius: 2,
          endRadius: diameter * 0.40
        )
      )
      .frame(width: diameter * 1.12, height: diameter * 0.30)
      .rotationEffect(.degrees(bandAngleDegrees + sin(driftPhase * 0.35) * 2))
      .offset(x: driftOffset, y: 0)
      .blur(radius: 5)
  }

  private var secondaryBlueMagentaCloud: some View {
    Ellipse()
      .fill(
        RadialGradient(
          colors: [
            Color(red: 0.42, green: 0.58, blue: 0.92).opacity(0.14 * opacityScale),
            Color(red: 0.62, green: 0.32, blue: 0.72).opacity(0.10 * opacityScale),
            Color.clear
          ],
          center: .center,
          startRadius: 1,
          endRadius: diameter * 0.30
        )
      )
      .frame(width: diameter * 0.78, height: diameter * 0.24)
      .rotationEffect(.degrees(bandAngleDegrees - sin(driftPhase * 0.28) * 2))
      .offset(x: diameter * 0.12 - driftOffset * 0.6, y: -diameter * 0.10)
      .blur(radius: 4)
  }

  /// Keeps nebula from washing out the face center.
  private var centerFaceFalloff: some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [
            Color.black.opacity(0.22 * opacityScale),
            Color.clear
          ],
          center: UnitPoint(x: 0.5, y: 0.50),
          startRadius: 0,
          endRadius: diameter * 0.34
        )
      )
  }
}
