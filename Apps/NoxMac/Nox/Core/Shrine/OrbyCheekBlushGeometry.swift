import CoreGraphics
import Foundation

/// Face-anchored layout for cheek blush marks (below eyes, never on lids).
struct OrbyCheekBlushLayout: Equatable {
  var leftCenter: CGPoint
  var rightCenter: CGPoint
  var markSize: CGSize
  /// Eye row only — used for face VStack; must not include blush extent.
  var eyeRowHeight: CGFloat
  /// Blush coordinate canvas (taller than eye row; drawn in overlay, does not push mouth).
  var stackHeight: CGFloat
  var rowWidth: CGFloat
}

enum OrbyCheekBlushGeometry {
  static let markWidth: CGFloat = 12
  static let markHeight: CGFloat = 5.5
  /// Must match `OrbyFaceView` eye–mouth `VStack` spacing.
  static let faceEyeMouthSpacing: CGFloat = 6
  /// Must match `OrbyMouthView` envelope height.
  static let mouthEnvelopeHeight: CGFloat = 18
  /// Fraction of the eye-bottom → mouth-top gap for mark center (`0.5` = midpoint).
  static let eyeToMouthVerticalBias: CGFloat = 0.5
  /// Minimum clearance from eye bottom to blush top (layout invariant).
  static let minGapBelowEyeBottom: CGFloat = 2
  /// Base outward shift from each eye center.
  static let outwardFromEyeCenter: CGFloat = 2
  /// Extra horizontal spread per side (left −, right +).
  static let horizontalSpreadPerSide: CGFloat = 0.5
  static let fillOpacity: Double = 0.62
  /// Soft edge on each mark only (kept small so eyes stay crisp).
  static let markBlurRadius: CGFloat = 1.9
  static let fadeInSeconds: TimeInterval = 0.24
  static let fadeOutSeconds: TimeInterval = 0.28

  static func fadeDuration(appearing: Bool) -> TimeInterval {
    appearing ? fadeInSeconds : fadeOutSeconds
  }

  static func layout(
    leftEye: OrbyEyeAppearance,
    rightEye: OrbyEyeAppearance,
    eyeSpacing: CGFloat
  ) -> OrbyCheekBlushLayout {
    let wL = OrbyEyeMetrics.scaled(leftEye.width)
    let wR = OrbyEyeMetrics.scaled(rightEye.width)
    let hL = OrbyEyeMetrics.scaled(leftEye.height)
    let hR = OrbyEyeMetrics.scaled(rightEye.height)

    let eyeBottom = eyeBottomFromRowTop(
      leftEye: leftEye,
      rightEye: rightEye,
      heightL: hL,
      heightR: hR
    )

    let eyeRowHeight = max(hL, hR) + max(abs(leftEye.verticalShift), abs(rightEye.verticalShift))
    let mouthTop = eyeRowHeight + faceEyeMouthSpacing
    let eyeToMouthGap = max(mouthTop - eyeBottom, markHeight + minGapBelowEyeBottom)
    let biasedCenterY = eyeBottom + eyeToMouthGap * eyeToMouthVerticalBias
    let minCenterY = eyeBottom + minGapBelowEyeBottom + markHeight / 2
    let cheekCenterY = max(biasedCenterY, minCenterY)

    let horizontalOutward = outwardFromEyeCenter + horizontalSpreadPerSide
    let leftEyeCenterX = -(eyeSpacing / 2 + wR / 2)
    let rightEyeCenterX = eyeSpacing / 2 + wL / 2

    let rowWidth = wL + eyeSpacing + wR + 6
    let stackHeight = max(eyeRowHeight, cheekCenterY + markHeight / 2 + 1)

    return OrbyCheekBlushLayout(
      leftCenter: CGPoint(x: leftEyeCenterX - horizontalOutward, y: cheekCenterY),
      rightCenter: CGPoint(x: rightEyeCenterX + horizontalOutward, y: cheekCenterY),
      markSize: CGSize(width: markWidth, height: markHeight),
      eyeRowHeight: eyeRowHeight,
      stackHeight: stackHeight,
      rowWidth: rowWidth
    )
  }

  /// Top of blush mark must sit below eye bottom (layout invariant).
  static func markTopIsBelowEyes(layout: OrbyCheekBlushLayout, leftEye: OrbyEyeAppearance, rightEye: OrbyEyeAppearance) -> Bool {
    let hL = OrbyEyeMetrics.scaled(leftEye.height)
    let hR = OrbyEyeMetrics.scaled(rightEye.height)
    let eyeBottom = eyeBottomFromRowTop(leftEye: leftEye, rightEye: rightEye, heightL: hL, heightR: hR)
    let markTop = layout.leftCenter.y - layout.markSize.height / 2
    return markTop >= eyeBottom + minGapBelowEyeBottom - 0.5
  }

  /// Bottom of each open eye from the top of the eye row (matches `OrbyEyeView` frame + offset).
  private static func eyeBottomFromRowTop(
    leftEye: OrbyEyeAppearance,
    rightEye: OrbyEyeAppearance,
    heightL: CGFloat,
    heightR: CGFloat
  ) -> CGFloat {
    let leftBottom = heightL + leftEye.verticalShift
    let rightBottom = heightR + rightEye.verticalShift
    return max(leftBottom, rightBottom)
  }
}
