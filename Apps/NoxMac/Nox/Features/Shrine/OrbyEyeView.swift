import SwiftUI

/// One Orby eye — narrows vertically for blink/sleep/squint (no separate eyelid layer).
struct OrbyEyeView: View {
  let width: CGFloat
  let baseHeight: CGFloat
  /// 0 = fully open, 1 = thin horizontal slit.
  let narrowAmount: Double
  let horizontalShift: CGFloat
  let verticalShift: CGFloat
  let rotationDegrees: CGFloat
  let color: Color
  var dimOpacity: Double = 1

  init(
    width: CGFloat,
    baseHeight: CGFloat,
    narrowAmount: Double,
    horizontalShift: CGFloat,
    verticalShift: CGFloat,
    rotationDegrees: CGFloat = 0,
    color: Color,
    dimOpacity: Double = 1
  ) {
    self.width = width
    self.baseHeight = baseHeight
    self.narrowAmount = narrowAmount
    self.horizontalShift = horizontalShift
    self.verticalShift = verticalShift
    self.rotationDegrees = rotationDegrees
    self.color = color
    self.dimOpacity = dimOpacity
  }

  private var renderedHeight: CGFloat {
    let t = min(max(narrowAmount, 0), 1)
    let minSlit: CGFloat = 1.6
    if t >= 0.98 { return minSlit }
    return max(minSlit, baseHeight * (1 - t * 0.92))
  }

  private var cornerRadius: CGFloat {
    min(2.2, max(0.8, renderedHeight * 0.45))
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(OrbyFaceShadowStyle.color)
        .frame(width: width, height: renderedHeight)
        .offset(
          x: horizontalShift + OrbyFaceShadowStyle.offset.width,
          y: verticalShift + OrbyFaceShadowStyle.offset.height
        )
        .opacity(dimOpacity)

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(color)
        .frame(width: width, height: renderedHeight)
        .offset(x: horizontalShift, y: verticalShift)
        .opacity(dimOpacity)
    }
    .rotationEffect(.degrees(rotationDegrees))
    .frame(width: width + 1, height: baseHeight, alignment: .center)
  }
}
