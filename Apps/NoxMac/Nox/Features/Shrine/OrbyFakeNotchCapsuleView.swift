import SwiftUI

/// Notch-extension shape: flat top and flat right edge (butts against real notch),
/// rounded bottom-left corner only.
struct OrbyTopAttachedNotchShape: Shape {
  var cornerRadius: CGFloat

  func path(in rect: CGRect) -> Path {
    let radius = min(cornerRadius, rect.width / 2, rect.height)
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.minX, y: rect.maxY - radius),
      control: CGPoint(x: rect.minX, y: rect.maxY)
    )
    path.closeSubpath()
    return path
  }
}

/// Fake notch capsule — always solid black. Width controlled by `widthFraction` (0…1).
/// When fraction < 1, the capsule is clipped from the left, revealing from the right (screen center).
struct OrbyFakeNotchCapsuleView: View {
  let state: FakeNotchVisualState
  let notchSize: CGSize
  let widthFraction: CGFloat

  private var cornerRadius: CGFloat { OrbyNotchDockingMetrics.fakeNotchCornerRadius }

  var body: some View {
    let visibleWidth = notchSize.width * min(max(widthFraction, 0), 1)
    OrbyTopAttachedNotchShape(cornerRadius: cornerRadius)
      .fill(Color(red: 0.04, green: 0.04, blue: 0.05))
      .frame(width: notchSize.width, height: notchSize.height)
      .frame(width: max(visibleWidth, 0.001), height: notchSize.height, alignment: .trailing)
      .clipped()
      .frame(width: notchSize.width, height: notchSize.height, alignment: .trailing)
      .shadow(color: Color.black.opacity(widthFraction > 0.01 ? 0.35 : 0), radius: 3, y: 1)
  }
}
