import SwiftUI

/// Single persistent morphing mouth for Orby — one filled blob, no overlays or view swaps.
struct OrbyMouthView: View {
  let parameters: OrbyMouthParameters
  let color: Color

  /// Fixed layout box so width/height never tween separately from shape morph.
  private static let envelopeWidth: CGFloat = 30
  private static let envelopeHeight: CGFloat = 22

  var body: some View {
    OrbyMouthShape(parameters: parameters)
      .fill(color.opacity(mouthFillOpacity))
      .frame(width: Self.envelopeWidth, height: Self.envelopeHeight)
      .offset(y: parameters.verticalOffset)
      .transaction { $0.animation = nil }
  }

  private var mouthFillOpacity: Double {
    parameters.openness > 0.2 ? 0.86 : 0.98
  }
}

struct OrbyMouthShape: Shape {
  var parameters: OrbyMouthParameters

  var animatableData: OrbyMouthParameters {
    get { parameters }
    set { parameters = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let openness = min(max(parameters.openness, 0), 1)
    let targetSpan = min(parameters.width, parameters.ovalWidth)
    let span = parameters.width + openness * (targetSpan - parameters.width)
    let thickness = parameters.lineHeight + openness * (parameters.ovalHeight - parameters.lineHeight)
    let bend = parameters.cornerLift * (1 - openness * 0.92)

    if openness > 0.08, parameters.ovalHeight >= parameters.ovalWidth * 0.9 {
      return verticalYawnCapsule(
        center: center,
        width: min(parameters.ovalWidth, 20),
        height: min(thickness, 26)
      )
    }

    return plasticineBlob(
      center: center,
      span: span,
      thickness: thickness,
      bend: bend,
      curvature: parameters.curvature
    )
  }

  /// One closed blob: neutral bar, smile arc, or open oval — same path family throughout.
  private func plasticineBlob(
    center: CGPoint,
    span: CGFloat,
    thickness: CGFloat,
    bend: CGFloat,
    curvature: CGFloat
  ) -> Path {
    var path = Path()
    let halfW = max(span, 3) / 2 - 1
    let radius = max(thickness, 2) / 2
    let yBase = center.y - bend * 0.1
    let left = CGPoint(x: center.x - halfW, y: yBase)
    let right = CGPoint(x: center.x + halfW, y: yBase)
    let control = CGPoint(x: center.x, y: center.y + bend * curvature)

    let controlTop = CGPoint(x: control.x, y: control.y - radius)
    let controlBottom = CGPoint(x: control.x, y: control.y + radius)

    path.move(to: CGPoint(x: left.x, y: left.y - radius))
    path.addQuadCurve(to: CGPoint(x: right.x, y: right.y - radius), control: controlTop)
    path.addArc(
      center: right,
      radius: radius,
      startAngle: .degrees(-90),
      endAngle: .degrees(90),
      clockwise: false
    )
    path.addQuadCurve(to: CGPoint(x: left.x, y: left.y + radius), control: controlBottom)
    path.addArc(
      center: left,
      radius: radius,
      startAngle: .degrees(90),
      endAngle: .degrees(270),
      clockwise: false
    )
    path.closeSubpath()
    return path
  }

  /// Soft vertical capsule for sleepy yawn (not a wide horizontal bar before open).
  private func verticalYawnCapsule(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
    let w = max(width, 4)
    let h = max(height, 5)
    let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    return Path(roundedRect: rect, cornerRadius: w / 2, style: .continuous)
  }
}

extension OrbyMouthParameters {
  static func interpolated(
    from a: OrbyMouthParameters,
    to b: OrbyMouthParameters,
    progress: Double
  ) -> OrbyMouthParameters {
    let t = CGFloat(min(max(progress, 0), 1))
    return OrbyMouthParameters(
      width: a.width + (b.width - a.width) * t,
      lineHeight: a.lineHeight + (b.lineHeight - a.lineHeight) * t,
      cornerLift: a.cornerLift + (b.cornerLift - a.cornerLift) * t,
      curvature: a.curvature + (b.curvature - a.curvature) * t,
      openness: a.openness + (b.openness - a.openness) * t,
      ovalWidth: a.ovalWidth + (b.ovalWidth - a.ovalWidth) * t,
      ovalHeight: a.ovalHeight + (b.ovalHeight - a.ovalHeight) * t,
      verticalOffset: a.verticalOffset + (b.verticalOffset - a.verticalOffset) * t
    )
  }
}

extension OrbyMouthParameters: VectorArithmetic {
  static var zero: OrbyMouthParameters { OrbyMouthParameters() }

  static func + (lhs: OrbyMouthParameters, rhs: OrbyMouthParameters) -> OrbyMouthParameters {
    OrbyMouthParameters(
      width: lhs.width + rhs.width,
      lineHeight: lhs.lineHeight + rhs.lineHeight,
      cornerLift: lhs.cornerLift + rhs.cornerLift,
      curvature: lhs.curvature + rhs.curvature,
      openness: lhs.openness + rhs.openness,
      ovalWidth: lhs.ovalWidth + rhs.ovalWidth,
      ovalHeight: lhs.ovalHeight + rhs.ovalHeight,
      verticalOffset: lhs.verticalOffset + rhs.verticalOffset
    )
  }

  static func - (lhs: OrbyMouthParameters, rhs: OrbyMouthParameters) -> OrbyMouthParameters {
    lhs + (-rhs)
  }

  static prefix func - (value: OrbyMouthParameters) -> OrbyMouthParameters {
    OrbyMouthParameters(
      width: -value.width,
      lineHeight: -value.lineHeight,
      cornerLift: -value.cornerLift,
      curvature: -value.curvature,
      openness: -value.openness,
      ovalWidth: -value.ovalWidth,
      ovalHeight: -value.ovalHeight,
      verticalOffset: -value.verticalOffset
    )
  }

  mutating func scale(by rhs: Double) {
    width *= rhs
    lineHeight *= rhs
    cornerLift *= rhs
    curvature *= rhs
    openness *= rhs
    ovalWidth *= rhs
    ovalHeight *= rhs
    verticalOffset *= rhs
  }

  var magnitudeSquared: Double {
    Double(
      width * width + lineHeight * lineHeight + cornerLift * cornerLift + curvature * curvature
        + openness * openness + ovalWidth * ovalWidth + ovalHeight * ovalHeight
        + verticalOffset * verticalOffset
    )
  }
}
