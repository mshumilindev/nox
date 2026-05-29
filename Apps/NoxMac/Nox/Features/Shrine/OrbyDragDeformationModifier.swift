import SwiftUI

/// Vector-aligned squash/stretch for the visible orb shell (not hit testing).
struct OrbyDragDeformationModifier: ViewModifier {
  let stretch: CGFloat
  let compression: CGFloat
  let angleRadians: CGFloat

  func body(content: Content) -> some View {
    content
      .rotationEffect(.radians(Double(angleRadians)))
      .scaleEffect(x: stretch, y: compression, anchor: .center)
      .rotationEffect(.radians(-Double(angleRadians)))
  }
}
