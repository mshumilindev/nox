import SwiftUI

/// Temporary idle overlays (tongue, bubble, sparkle) — not a second mouth.
struct OrbyIdleMicroOverlayLayer: View {
  let overlay: OrbyIdleMicroOverlay

  var body: some View {
    ZStack {
      if overlay.tongueProgress > 0.01 {
        tongue
      }
      if overlay.bubbleOpacity > 0.01, let center = overlay.bubbleCenter {
        bubble(at: center)
      }
      if overlay.sparkleOpacity > 0.01 {
        sparkle
      }
      if overlay.animeSparkleOpacity > 0.01 {
        animeSparkles
      }
    }
    .allowsHitTesting(false)
  }

  /// 1–3 tiny glints near the eyes / upper cheeks for the anime self-satisfied beat.
  private var animeSparkles: some View {
    ZStack {
      glint(at: CGPoint(x: 26, y: 24), size: 4.0)
      glint(at: CGPoint(x: 52, y: 21), size: 3.2)
      glint(at: CGPoint(x: 40, y: 14), size: 2.6)
    }
    .opacity(overlay.animeSparkleOpacity)
  }

  private func glint(at point: CGPoint, size: CGFloat) -> some View {
    OrbyFourPointGlint()
      .fill(Color(red: 1.0, green: 1.0, blue: 0.94))
      .frame(width: size, height: size)
      .shadow(color: Color.white.opacity(0.6), radius: 2)
      .position(point)
  }

  private var tongue: some View {
    Capsule()
      .fill(
        LinearGradient(
          colors: [
            Color(red: 1.0, green: 0.70, blue: 0.86),
            Color(red: 0.95, green: 0.38, blue: 0.66)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: 9.5, height: 5.0 + 9.5 * overlay.tongueProgress)
      .offset(x: 0, y: 18)
      .scaleEffect(0.35 + 0.75 * overlay.tongueProgress)
      .shadow(color: Color(red: 1, green: 0.35, blue: 0.68).opacity(0.35), radius: 2)
  }

  private func bubble(at center: CGPoint) -> some View {
    Circle()
      .fill(Color.white.opacity(0.18))
      .overlay {
        Circle()
          .stroke(Color.white.opacity(0.78), lineWidth: 1.25)
      }
      .overlay {
        Circle()
          .fill(Color.white.opacity(0.75))
          .frame(width: 2.5, height: 2.5)
          .offset(x: -overlay.bubbleRadius * 0.25, y: -overlay.bubbleRadius * 0.25)
      }
      .frame(width: overlay.bubbleRadius * 2, height: overlay.bubbleRadius * 2)
      .position(center)
      .opacity(overlay.bubbleOpacity)
  }

  private var sparkle: some View {
    Image(systemName: "sparkle")
      .font(.system(size: 9, weight: .bold))
      .foregroundStyle(Color.white.opacity(0.95))
      .shadow(color: Color.white.opacity(0.60), radius: 4)
      .position(overlay.sparklePoint)
      .opacity(overlay.sparkleOpacity)
  }
}
