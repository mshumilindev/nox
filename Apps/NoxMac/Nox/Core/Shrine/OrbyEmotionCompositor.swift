import Foundation

/// Maps base mood + intensity + visual phase → render channels (eyes, mouth, tint, bezel, particles).
enum OrbyEmotionCompositor {
  static func compose(
    mood: OrbyMood,
    intensity: OrbyEmotionIntensity,
    phase: OrbyMiniVisualPhase,
    eyelidClosure: Double,
    isExcited: Bool
  ) -> OrbyEmotionAppearance {
    var appearance = baseAppearance(mood: mood, intensity: intensity)
    if isExcited {
      appearance = applyExcited(appearance)
    }
    appearance = applyPhase(appearance, phase: phase, eyelidClosure: eyelidClosure, isExcited: isExcited)
    return appearance
  }

  private static func baseAppearance(mood: OrbyMood, intensity: OrbyEmotionIntensity) -> OrbyEmotionAppearance {
    switch mood {
    case .neutral:
      return .neutralDefault

    case .focused:
      var a = eyePair(leftH: 6, rightH: 5.5)
      a.mouth = OrbyMouthParameters(width: 11, lineHeight: 2.2)
      a.tint.coolShift = intensity == .strong ? 0.12 : 0.06
      a.bezel.matte = intensity == .strong
      a.blinkIntervalScale = 1.35
      a.trackingScale = intensity == .strong ? 0.82 : 0.92
      if intensity == .strong {
        a.glowStrength = 0.06
      }
      return a

    case .deepFocus:
      var a = eyePair(leftH: 5.5, rightH: 5)
      a.mouth = OrbyMouthParameters(width: 10, lineHeight: 2)
      a.tint.coolShift = 0.14
      a.bezel.matte = true
      a.bezel.prominenceScale = 0.92
      a.blinkIntervalScale = 1.8
      a.trackingScale = 0.72
      a.glowStrength = 0.04
      return a

    case .pleased:
      var a = eyePair(leftH: 9, rightH: 9, rightVerticalShift: 0)
      let lift: CGFloat = intensity == .strong ? 6.5 : 5
      a.mouth = OrbyMouthParameters(width: 15, lineHeight: 2.4, cornerLift: lift, curvature: 0.72)
      a.tint.warmShift = intensity == .strong ? 0.14 : 0.08
      a.microBob = 0.4
      if intensity != .subtle {
        a.overlayParticles = .glints(intensity == .strong ? 2 : 1)
      }
      a.cheekBlushStrength = intensity == .strong ? 0.65 : 0.55
      return a

    case .excited:
      return applyExcited(.neutralDefault)

    case .curious:
      var a = eyePair()
      a.mouth = OrbyMouthParameters(width: 12, lineHeight: 2.3, cornerLift: 2, curvature: 0.4)
      a.tint.cyanShift = 0.1
      if intensity == .strong {
        a.overlayParticles = .thoughtDots(1)
      }
      return a

    case .thinking:
      var a = eyePair(leftH: 8.5, rightH: 7.5)
      a.mouth = OrbyMouthParameters(width: 8, lineHeight: 2.5)
      a.tint.cyanShift = 0.06
      a.overlayParticles = .thoughtDots(intensity == .strong ? 3 : 2)
      a.blinkIntervalScale = 1.2
      return a

    case .concerned:
      var a = eyePair(leftH: 9.5, rightH: 7.5)
      a.mouth = OrbyMouthParameters(width: 11, lineHeight: 2.2, cornerLift: -1.5, curvature: 0.35)
      a.tint.amberShift = intensity == .strong ? 0.12 : 0.06
      a.bezel = OrbyBezelModifiers(rimAmber: 0.08, prominenceScale: 1.05)
      a.blinkIntervalScale = 1.15
      return a

    case .skeptical:
      var a = eyePair(leftH: 6.5, rightH: 8)
      a.mouth = OrbyMouthParameters(width: 12, lineHeight: 2, cornerLift: -2, curvature: 0.2)
      a.tint.amberShift = 0.04
      a.tint.desaturation = 0.08
      a.blinkIntervalScale = 1.25
      a.trackingScale = 0.88
      return a

    case .annoyed:
      let red = intensity == .extreme ? 0.22 : (intensity == .strong ? 0.16 : 0.08)
      var a = eyePair(leftH: 7.5, rightH: 7)
      a.mouth = OrbyMouthParameters(width: 12, lineHeight: 2, cornerLift: -2.5, curvature: 0.15)
      a.tint.redShift = red
      a.bezel = OrbyBezelModifiers(rimRed: red * 1.2)
      a.trackingScale = 0.75
      a.blinkIntervalScale = 0.85
      if intensity == .strong || intensity == .extreme {
        a.overlayParticles = .steamPuffs(intensity == .extreme ? 2 : 1)
      }
      return a

    case .alarmed:
      var a = eyePair(leftH: 11, rightH: 10)
      a.mouth = OrbyMouthParameters(openness: 1, ovalWidth: 9, ovalHeight: 5)
      let amber = intensity == .strong ? 0.2 : 0.12
      a.tint.amberShift = amber
      a.tint.redShift = intensity == .strong ? 0.08 : 0
      a.bezel = OrbyBezelModifiers(rimRed: a.tint.redShift, rimAmber: amber, prominenceScale: 1.12)
      a.glowStrength = 0.1
      a.trackingScale = 0.5
      a.blinkIntervalScale = 2
      if intensity != .subtle {
        a.overlayParticles = .alarmRing
      }
      return a

    case .sleepy, .tired:
      var a = eyePair(leftH: 5.5, rightH: 5)
      a.mouth = OrbyMouthParameters(width: 10, lineHeight: 2.2)
      a.tint.coolShift = mood == .tired ? 0.1 : 0.06
      a.tint.brightness = 0.94
      a.blinkIntervalScale = 0.75
      a.microBob = mood == .tired ? 0.25 : 0.15
      return a

    case .passive, .muted:
      var a = OrbyEmotionAppearance.neutralDefault
      a.mouth = OrbyMouthParameters(width: 11, lineHeight: 2.2)
      a.tint.desaturation = mood == .muted ? 0.18 : 0.1
      a.blinkIntervalScale = 1.4
      a.trackingScale = 0.85
      return a

    case .disconnected:
      var a = eyePair(leftH: 7, rightH: 6.5)
      a.mouth = OrbyMouthParameters(width: 11, lineHeight: 2)
      a.tint.desaturation = 0.35
      a.tint.brightness = 0.88
      a.bezel.prominenceScale = 0.9
      a.eyesDimmed = true
      if intensity == .strong {
        a.overlayParticles = .sparks(1)
      }
      return a

    case .overloaded:
      var a = eyePair(leftH: 10, rightH: 9.5)
      a.mouth = OrbyMouthParameters(width: 10, lineHeight: 2.3, cornerLift: -1)
      let amber = intensity == .extreme ? 0.18 : 0.1
      a.tint.amberShift = amber
      a.tint.redShift = intensity == .strong || intensity == .extreme ? 0.1 : 0.04
      a.bezel = OrbyBezelModifiers(rimAmber: amber, prominenceScale: 1.08)
      a.microBob = 0.35
      a.overlayParticles = .sparks(intensity == .extreme ? 3 : 2)
      return a

    case .nightWatch:
      var a = eyePair(leftH: 6, rightH: 5.5)
      a.mouth = OrbyMouthParameters(width: 10, lineHeight: 2)
      a.tint.coolShift = 0.16
      a.tint.brightness = 0.9
      a.glowStrength = 0.03
      a.bezel.prominenceScale = 0.88
      a.blinkIntervalScale = 1.6
      a.trackingScale = 0.65
      return a
    }
  }

  private static func applyExcited(_ base: OrbyEmotionAppearance) -> OrbyEmotionAppearance {
    var a = base
    let eyes = OrbyEmotionAppearance.canonicalEyes(leftHeight: 11, rightHeight: 10)
    a.leftEye = eyes.left
    a.rightEye = eyes.right
    a.eyeSpacing = OrbyEmotionAppearance.canonicalEyeSpacing
    a.mouth = OrbyPhaseMouthPresets.hoverExcited
    a.tint.warmShift = 0.14
    a.tint.redShift = 0.07
    a.tint.brightness = 1.06
    a.faceBrightness = 1.08
    a.glowStrength = 0.08
    a.cheekBlushStrength = 1
    a.microBob = 0.5
    a.blinkIntervalScale = 0
    a.trackingScale = 1
    a.overlayParticles = .none
    a.eyesDimmed = false
    return a
  }

  private static func applyPhase(
    _ base: OrbyEmotionAppearance,
    phase: OrbyMiniVisualPhase,
    eyelidClosure: Double,
    isExcited: Bool
  ) -> OrbyEmotionAppearance {
    var a = base
    switch phase {
    case .dragging:
      a.leftEye = OrbyEyeAppearance(width: 9.5, height: 10.5, verticalShift: -0.5)
      a.rightEye = a.leftEye
      a.mouth = OrbyMouthParameters(openness: 1, ovalWidth: 7, ovalHeight: 7)
      a.overlayParticles = .none
      a.trackingScale = 0.4
    case .postDragDazed:
      a.leftEye = OrbyEyeAppearance(width: 9, height: 6)
      a.rightEye = a.leftEye
      a.mouth = OrbyWakeMouthParameters.closedSlit
      a.tint.brightness = 0.9
      a.tint.coolShift = 0.08
      a.overlayParticles = .none
      a.trackingScale = 0
    case .asleep:
      a.leftEye = OrbyEyeAppearance(width: 9, height: 8, verticalShift: 1)
      a.rightEye = a.leftEye
      a.mouth = OrbyWakeMouthParameters.closedSlit
      a.tint.brightness = 0.9
      a.tint.coolShift = 0.08
      a.overlayParticles = .none
      a.trackingScale = 0
    case .sleepyTransition(let progress):
      a.leftEye = OrbyEyeAppearance(width: 9, height: 8, verticalShift: 1)
      a.rightEye = a.leftEye
      let sleepyMouth = OrbyMouthParameters(width: 10, lineHeight: 2)
      if progress > 0.82 {
        let p = OrbyMiniVisualEasing.smoothstep((progress - 0.82) / 0.18)
        a.mouth = OrbyMouthParameters.interpolated(
          from: sleepyMouth,
          to: OrbyWakeMouthParameters.closedSlit,
          progress: p
        )
      } else {
        a.mouth = sleepyMouth
      }
      a.tint.brightness = 0.92
      a.tint.coolShift = 0.06
      a.overlayParticles = .none
      a.trackingScale = max(0, 1 - progress)
    case .wakingYawn(let progress):
      a.leftEye = OrbyEyeAppearance(width: 9, height: 8, verticalShift: 1)
      a.rightEye = a.leftEye
      a.mouth = OrbyWakeMouthParameters.yawn(progress: progress)
      a.overlayParticles = .none
      a.trackingScale = 0
    case .wakingDoubleBlink, .wakingSquint, .wakingGlanceRight, .wakingGlanceLeft, .wakingQuickBlink:
      a.mouth = OrbyWakeMouthParameters.closedSlit
      a.overlayParticles = .none
      a.trackingScale = 0
    case .launchGreeting(let progress):
      let hello = OrbyLaunchGreetingAnimator.helloProgress(from: progress)
      let helloEmphasis = hello > 0
        ? sin(min(max(hello, 0), 1) * .pi * 3.0) * 0.5 + 0.5
        : 0
      a.leftEye = OrbyEyeAppearance(
        width: OrbyEmotionAppearance.canonicalEyeWidth,
        height: 10 + CGFloat(helloEmphasis) * 0.5,
        verticalShift: -0.5 - CGFloat(helloEmphasis) * 0.2
      )
      a.rightEye = a.leftEye
      a.eyeSpacing = OrbyEmotionAppearance.canonicalEyeSpacing
      a.mouth = OrbyLaunchGreetingAnimator.mouth(progress: progress)
      a.tint.warmShift = min(a.tint.warmShift + 0.12 + helloEmphasis * 0.03, 0.28)
      a.faceBrightness = 1.08 + helloEmphasis * 0.03
      a.glowStrength = max(a.glowStrength, 0.055 + helloEmphasis * 0.018)
      a.blinkIntervalScale = 0
      a.trackingScale = OrbyLaunchGreetingAnimator.eyeTrackingFactor(progress: progress)
      a.overlayParticles = hello > 0 ? .helloSyllables(progress: hello) : .none
      a.eyesDimmed = false
      let blushRamp = OrbyMiniVisualEasing.smoothstep(min(max(progress / 0.18, 0), 1))
      a.cheekBlushStrength = min(1, 0.36 + blushRamp * 0.52 + helloEmphasis * 0.08)
    case .hoverExcited:
      if !isExcited { break }
      return applyExcited(base)
    case .awake:
      break
    }
    _ = eyelidClosure
    return a
  }

  /// Canonical row layout; mood expression adjusts heights only.
  private static func eyePair(
    leftH: CGFloat = OrbyEmotionAppearance.canonicalLeftHeight,
    rightH: CGFloat = OrbyEmotionAppearance.canonicalRightHeight,
    rightVerticalShift: CGFloat = OrbyEmotionAppearance.canonicalRightVerticalShift
  ) -> OrbyEmotionAppearance {
    let eyes = OrbyEmotionAppearance.canonicalEyes(
      leftHeight: leftH,
      rightHeight: rightH,
      rightVerticalShift: rightVerticalShift
    )
    return OrbyEmotionAppearance(
      leftEye: eyes.left,
      rightEye: eyes.right,
      eyeSpacing: OrbyEmotionAppearance.canonicalEyeSpacing,
      mouth: OrbyMouthParameters(),
      tint: OrbyTintAppearance(),
      bezel: OrbyBezelModifiers()
    )
  }
}
