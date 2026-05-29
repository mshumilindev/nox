import Foundation
import SwiftUI

struct OrbyEyeAppearance: Equatable {
  var width: CGFloat = 9.5
  var height: CGFloat = 9.5
  var horizontalShift: CGFloat = 0
  var verticalShift: CGFloat = 0
}

/// Tint layered on orb gradient (not a full repaint).
struct OrbyTintAppearance: Equatable {
  var redShift: Double = 0
  var warmShift: Double = 0
  var amberShift: Double = 0
  var cyanShift: Double = 0
  var coolShift: Double = 0
  var desaturation: Double = 0
  var brightness: Double = 1
}

struct OrbyBezelModifiers: Equatable {
  var rimRed: Double = 0
  var rimAmber: Double = 0
  var prominenceScale: Double = 1
  var matte: Bool = false
}

enum OrbyOverlayParticle: Equatable {
  case none
  case steamPuffs(Int)
  case sparks(Int)
  case glints(Int)
  case thoughtDots(Int)
  case alarmRing
  case helloSyllables(progress: Double)
}

/// Full face/orb emotional snapshot (base + intensity; phase may override in compositor).
struct OrbyEmotionAppearance: Equatable {
  var leftEye: OrbyEyeAppearance
  var rightEye: OrbyEyeAppearance
  var eyeSpacing: CGFloat = OrbyEmotionAppearance.canonicalEyeSpacing
  var mouth: OrbyMouthParameters
  var tint: OrbyTintAppearance
  var bezel: OrbyBezelModifiers
  var faceBrightness: Double = 1
  var glowStrength: Double = 0
  var microBob: CGFloat = 0
  var blinkIntervalScale: Double = 1
  var overlayParticles: OrbyOverlayParticle = .none
  var eyesDimmed: Bool = false
  var trackingScale: Double = 1
  /// 0…1 — rosy cheek spots on the face (hover-excited).
  var cheekBlushStrength: Double = 0

  /// Fixed eye-row layout for all awake moods (expression = height only; not spacing/shift).
  /// Spacing matches legacy `focused` (16). Default heights match `curious` — slight smile mood.
  static let canonicalEyeSpacing: CGFloat = 16
  static let canonicalEyeWidth: CGFloat = 9.5
  static let canonicalLeftHeight: CGFloat = 9.5
  static let canonicalRightHeight: CGFloat = 7.5
  static let canonicalRightVerticalShift: CGFloat = 0

  static func canonicalEyes(
    leftHeight: CGFloat = canonicalLeftHeight,
    rightHeight: CGFloat = canonicalRightHeight,
    rightVerticalShift: CGFloat = canonicalRightVerticalShift
  ) -> (left: OrbyEyeAppearance, right: OrbyEyeAppearance) {
    (
      OrbyEyeAppearance(width: canonicalEyeWidth, height: leftHeight),
      OrbyEyeAppearance(
        width: canonicalEyeWidth,
        height: rightHeight,
        verticalShift: rightVerticalShift
      )
    )
  }

  /// Subtle L/R size difference so Orby reads alive at rest (not flat-dead).
  static let neutralDefault: OrbyEmotionAppearance = {
    let eyes = canonicalEyes()
    return OrbyEmotionAppearance(
      leftEye: eyes.left,
      rightEye: eyes.right,
      eyeSpacing: canonicalEyeSpacing,
      mouth: OrbyMouthParameters(width: 12, lineHeight: 2.5),
      tint: OrbyTintAppearance(),
      bezel: OrbyBezelModifiers()
    )
  }()
}
