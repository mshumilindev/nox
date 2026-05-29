import SwiftUI

/// Soft horizontal cheek capsules — below the eyes, behind the eye layer.
struct OrbyCheekBlushView: View {
  let strength: Double
  let layout: OrbyCheekBlushLayout

  private var effectiveStrength: Double {
    min(max(strength, 0), 1)
  }

  var body: some View {
    ZStack {
      mark(at: layout.leftCenter)
      mark(at: layout.rightCenter)
    }
    .frame(width: layout.rowWidth, height: layout.stackHeight)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func mark(at center: CGPoint) -> some View {
    Capsule(style: .continuous)
      .fill(
        OrbyCheekBlushStyle.fill.opacity(OrbyCheekBlushGeometry.fillOpacity * effectiveStrength)
      )
      .frame(width: layout.markSize.width, height: layout.markSize.height)
      .blur(radius: OrbyCheekBlushGeometry.markBlurRadius)
      .position(x: layout.rowWidth / 2 + center.x, y: center.y)
  }
}

enum OrbyCheekBlushStyle {
  /// Rose / pink on dark purple face — saturated so marks read clearly at mini size.
  static let fill = Color(red: 1.0, green: 0.36, blue: 0.56)
}
