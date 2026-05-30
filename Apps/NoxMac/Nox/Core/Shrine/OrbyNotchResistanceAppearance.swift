import CoreGraphics
import Foundation

/// Tension-driven angry face overlay for notch undock resistance (no mood swap).
enum OrbyNotchResistanceAppearance {
  static func apply(tension: CGFloat, to base: OrbyEmotionAppearance) -> OrbyEmotionAppearance {
    let t = min(max(tension, 0), 1)
    guard t > 0.001 else { return base }

    var appearance = base
    appearance.cheekBlushStrength = 0
    appearance.overlayParticles = .none
    appearance.trackingScale *= 1 - Double(t) * 0.35
    appearance.blinkIntervalScale *= 1 + Double(t) * 0.25

    if t < 0.12 {
      appearance.trackingScale *= 0.95
      return appearance
    }

    // Anger ramps up faster and harder — annoyed almost immediately, rage by ~55%.
    let annoyedBlend = smoothstep((t - 0.12) / 0.18)
    let angryBlend = smoothstep((t - 0.30) / 0.20)
    let rageBlend = smoothstep((t - 0.55) / 0.20)

    let redShift = 0.10 * annoyedBlend + 0.22 * angryBlend + 0.35 * rageBlend
    appearance.tint.redShift = max(appearance.tint.redShift, redShift)
    appearance.tint.warmShift = max(appearance.tint.warmShift, 0.08 * angryBlend + 0.16 * rageBlend)
    appearance.tint.coolShift *= 1 - Double(annoyedBlend) * 0.5
    appearance.bezel.rimRed = max(appearance.bezel.rimRed, redShift * 1.15)

    let baseLeft = OrbyEmotionAppearance.canonicalLeftHeight
    let baseRight = OrbyEmotionAppearance.canonicalRightHeight
    let narrow = annoyedBlend * 0.18 + angryBlend * 0.32 + rageBlend * 0.42
    let leftH = baseLeft * (1 - narrow)
    let rightH = baseRight * (1 - narrow)

    let eyes = OrbyEmotionAppearance.canonicalEyes(
      leftHeight: leftH,
      rightHeight: rightH,
      rightVerticalShift: 0.6 * angryBlend + 1.0 * rageBlend
    )
    appearance.leftEye = eyes.left
    appearance.rightEye = eyes.right
    appearance.eyeSpacing = OrbyEmotionAppearance.canonicalEyeSpacing - (0.4 * annoyedBlend + 0.8 * angryBlend)

    let eyePress = 0.4 * annoyedBlend + 1.0 * angryBlend + 1.4 * rageBlend
    appearance.leftEye.verticalShift += eyePress
    appearance.rightEye.verticalShift += eyePress
    appearance.leftEye.horizontalShift += 0.3 * angryBlend + 0.6 * rageBlend
    appearance.rightEye.horizontalShift -= 0.3 * angryBlend + 0.6 * rageBlend

    let slant = 6 * angryBlend + 10 * rageBlend
    appearance.leftEye.rotationDegrees = slant
    appearance.rightEye.rotationDegrees = -slant

    var mouth = appearance.mouth
    mouth.openness = 0
    mouth.width = 13 - 3 * angryBlend - 2 * rageBlend
    mouth.lineHeight = 2.2 + 0.3 * rageBlend
    mouth.cornerLift = -1.2 * annoyedBlend - 2.8 * angryBlend - 4.0 * rageBlend
    mouth.curvature = max(0.05, 0.35 - 0.25 * angryBlend - 0.2 * rageBlend)
    appearance.mouth = mouth

    return appearance
  }

  private static func smoothstep(_ x: CGFloat) -> CGFloat {
    let t = min(max(x, 0), 1)
    return t * t * (3 - 2 * t)
  }
}
