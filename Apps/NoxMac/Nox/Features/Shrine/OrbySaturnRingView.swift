import SwiftUI

enum OrbySaturnRingLayer {
  case back
  case front
}

/// Saturn-like tilted rings + orbiting satellite for `saturnRingOrbit`. Hit testing off.
struct OrbySaturnRingView: View {
  let overlay: OrbyIdleMicroOverlay
  let layer: OrbySaturnRingLayer
  let orbDiameter: CGFloat

  private let ringWidth: CGFloat = 112
  private let ringHeight: CGFloat = 30
  private let centerYOffset: CGFloat = 4

  var body: some View {
    if overlay.saturnRingOpacity > 0.001 {
      ringContent
    }
  }

  private var ringContent: some View {
    let opacity = overlay.saturnRingOpacity
    let center = CGPoint(x: orbDiameter / 2, y: orbDiameter / 2 + centerYOffset)
    let tilt = overlay.saturnRingTiltDegrees
    let scale = 0.92 + 0.08 * min(max(overlay.saturnRingProgress / 0.12, 0), 1)

    return ZStack {
      if layer == .back {
        ringArc(trim: 0.5...1.0, opacity: 0.24 * opacity, stroke: 1.0, scale: scale, center: center, tilt: tilt)
        if overlay.saturnSatelliteFrontness <= 0 {
          satellite(at: center, tilt: tilt, scale: scale, front: false)
        }
      } else {
        ringArc(trim: 0.0...0.52, opacity: 0.46 * opacity, stroke: 1.4, scale: scale, center: center, tilt: tilt)
        ringArc(trim: 0.0...0.52, opacity: 0.18 * opacity, stroke: 2.2, scale: scale * 1.04, center: center, tilt: tilt)
        if overlay.saturnSatelliteFrontness > 0 {
          satellite(at: center, tilt: tilt, scale: scale, front: true)
        }
      }
    }
    .frame(width: orbDiameter, height: orbDiameter)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func ringArc(
    trim: ClosedRange<CGFloat>,
    opacity: Double,
    stroke: CGFloat,
    scale: CGFloat,
    center: CGPoint,
    tilt: Double
  ) -> some View {
    Ellipse()
      .trim(from: trim.lowerBound, to: trim.upperBound)
      .stroke(
        LinearGradient(
          colors: [
            Color(red: 0.86, green: 0.84, blue: 0.98).opacity(opacity),
            Color(red: 0.72, green: 0.78, blue: 0.96).opacity(opacity * 0.85),
            Color(red: 0.92, green: 0.88, blue: 0.78).opacity(opacity * 0.35)
          ],
          startPoint: .leading,
          endPoint: .trailing
        ),
        style: StrokeStyle(lineWidth: stroke, lineCap: .round)
      )
      .frame(width: ringWidth * scale, height: ringHeight * scale)
      .rotationEffect(.degrees(tilt))
      .position(center)
  }

  @ViewBuilder
  private func satellite(at center: CGPoint, tilt: Double, scale: CGFloat, front: Bool) -> some View {
    let pos = satellitePosition(center: center, tilt: tilt, scale: scale)
    let depth = abs(overlay.saturnSatelliteFrontness)
    let size: CGFloat = front ? 4.0 : 3.2
    let alpha = overlay.saturnSatelliteOpacity * (front ? 0.92 : 0.38)
    if alpha > 0.01 {
      ZStack {
        Circle()
          .fill(Color(red: 0.55, green: 0.48, blue: 0.72).opacity(alpha * 0.35))
          .frame(width: size + 1.2, height: size + 1.2)
          .blur(radius: 0.6)
        Circle()
          .fill(Color(red: 0.90, green: 0.93, blue: 1.0).opacity(alpha))
          .frame(width: size, height: size)
        Circle()
          .fill(Color.white.opacity(alpha * 0.65))
          .frame(width: size * 0.35, height: size * 0.35)
          .offset(x: -size * 0.18, y: -size * 0.18)
      }
      .scaleEffect(front ? 1 : 0.82)
      .opacity(0.55 + 0.45 * depth)
      .position(pos)
    }
  }

  private func satellitePosition(center: CGPoint, tilt: Double, scale: CGFloat) -> CGPoint {
    let rx = ringWidth * 0.5 * scale
    let ry = ringHeight * 0.5 * scale
    let angle = overlay.saturnSatelliteAngle
    let x = cos(angle) * rx
    let y = sin(angle) * ry
    let rad = tilt * .pi / 180
    let rotX = x * cos(rad) - y * sin(rad)
    let rotY = x * sin(rad) + y * cos(rad)
    return CGPoint(x: center.x + rotX, y: center.y + rotY)
  }
}
