import CoreGraphics
import Foundation

enum OrbyIdleMicrobehaviorAnimation {
  static func frame(
    for kind: OrbyIdleMicrobehavior,
    progress: Double,
    baseMouth: OrbyMouthParameters
  ) -> OrbyIdleMicrobehaviorFrame {
    let t = min(max(progress, 0), 1)
    switch kind {
    case .microSmile: return microSmile(t, base: baseMouth)
    case .eyeWander: return eyeWander(t)
    case .glanceAround: return glanceAround(t)
    case .humPulse: return humPulse(t)
    case .selfPolish: return selfPolish(t, base: baseMouth)
    case .tonguePeek: return tonguePeek(t, base: baseMouth)
    case .bubbleBlow: return bubbleBlow(t, base: baseMouth)
    case .cheekPuff: return cheekPuff(t, base: baseMouth)
    case .tinyYawn: return tinyYawn(t, base: baseMouth)
    case .sleepyNod: return sleepyNod(t, base: baseMouth)
    case .sparkleCatch: return sparkleCatch(t, base: baseMouth)
    case .sideEye: return sideEye(t, base: baseMouth)
    case .tinySneeze: return tinySneeze(t, base: baseMouth)
    case .pixelShiver: return pixelShiver(t)
    case .animeSelfSatisfied: return animeSelfSatisfied(t, base: baseMouth)
    case .noirDetective: return noirDetective(t, base: baseMouth)
    case .cosmicCometWatch: return cosmicCometWatch(t, base: baseMouth)
    case .catMode: return catMode(t, base: baseMouth)
    case .blackHoleNibble: return blackHoleNibble(t, base: baseMouth)
    }
  }

  /// Reveal envelope: ease 0→1 by `inEnd`, hold, ease 1→0 from `outStart` to 1.
  private static func reveal(_ t: Double, inEnd: Double, outStart: Double) -> Double {
    if t < inEnd { return OrbyMiniVisualEasing.smoothstep(t / inEnd) }
    if t < outStart { return 1 }
    return 1 - OrbyMiniVisualEasing.smoothstep((t - outStart) / max(0.0001, 1 - outStart))
  }

  static func apply(_ frame: OrbyIdleMicrobehaviorFrame, to appearance: OrbyEmotionAppearance) -> OrbyEmotionAppearance {
    var a = appearance
    if let mouth = frame.mouth { a.mouth = mouth }
    a.leftEye.height *= frame.leftEyeHeightScale
    a.rightEye.height *= frame.rightEyeHeightScale
    a.tint.warmShift += frame.extraWarmth
    if let tracking = frame.trackingFactor { a.trackingScale *= tracking }
    return a
  }

  // MARK: - Behaviors

  private static func microSmile(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let curve = sinCurve(t, in: 0.10...0.86)
    var mouth = base
    mouth.width = base.width * (1 + 0.28 * curve)
    mouth.cornerLift = max(base.cornerLift, 5.2 * curve)
    mouth.curvature = max(base.curvature, 0.78)
    return OrbyIdleMicrobehaviorFrame(
      scriptedEyeOffset: CGSize(width: 0, height: -1.2 * curve),
      mouth: mouth,
      leftEyeHeightScale: 1 + 0.08 * curve,
      rightEyeHeightScale: 1 + 0.08 * curve,
      faceNudge: CGSize(width: 0, height: -1.8 * curve),
      extraOrbScale: 1 + 0.012 * curve,
      extraWarmth: 0.12 * curve,
      trackingFactor: 0.25
    )
  }

  private static func eyeWander(_ t: Double) -> OrbyIdleMicrobehaviorFrame {
    let seg = t * 3
    let offset: CGSize
    if seg < 1 {
      let p = OrbyMiniVisualEasing.smoothstep(seg)
      offset = CGSize(width: -7.0 * p, height: 1.1 * p)
    } else if seg < 2 {
      let p = OrbyMiniVisualEasing.smoothstep(seg - 1)
      offset = CGSize(width: -7.0 + 14.0 * p, height: 1.1 - 2.2 * p)
    } else {
      let p = OrbyMiniVisualEasing.smoothstep(seg - 2)
      offset = CGSize(width: 7.0 * (1 - p), height: -1.1 * (1 - p))
    }
    return OrbyIdleMicrobehaviorFrame(
      scriptedEyeOffset: offset,
      trackingFactor: 0.08,
      headTurnYExtra: Double(offset.width) * 0.65
    )
  }

  private static func glanceAround(_ t: Double) -> OrbyIdleMicrobehaviorFrame {
    let offset: CGSize
    if t < 0.28 {
      let p = OrbyMiniVisualEasing.smoothstep(t / 0.28)
      offset = CGSize(width: -7.4 * p, height: -0.8 * p)
    } else if t < 0.55 {
      let p = OrbyMiniVisualEasing.smoothstep((t - 0.28) / 0.27)
      offset = CGSize(width: -7.4 + 14.8 * p, height: -0.8 + 1.6 * p)
    } else {
      let p = OrbyMiniVisualEasing.smoothstep((t - 0.55) / 0.45)
      offset = CGSize(width: 7.4 * (1 - p), height: 0.8 * (1 - p))
    }
    return OrbyIdleMicrobehaviorFrame(
      scriptedEyeOffset: offset,
      trackingFactor: 0.05,
      headTurnYExtra: Double(offset.width) * 0.72
    )
  }

  private static func humPulse(_ t: Double) -> OrbyIdleMicrobehaviorFrame {
    let pulse = 0.5 + 0.5 * sin(t * .pi * 2)
    return OrbyIdleMicrobehaviorFrame(
      extraOrbScale: 1 + 0.026 * pulse,
      extraWarmth: 0.08 * pulse,
      trackingFactor: 1
    )
  }

  private static func selfPolish(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let curve = sinCurve(t, in: 0.1...0.85)
    var mouth = base
    mouth.cornerLift = max(base.cornerLift, 4.6 * curve)
    let glance = sinCurve(t, in: 0.05...0.55)
    return OrbyIdleMicrobehaviorFrame(
      scriptedEyeOffset: CGSize(width: -5.4 * glance, height: -3.4 * glance),
      mouth: mouth,
      trackingFactor: 0.15,
      faceTiltDegrees: -0.8 * curve,
      overlay: OrbyIdleMicroOverlay(
        rimGlintOpacity: 1.0 * curve,
        rimGlintProgress: t
      )
    )
  }

  private static func tonguePeek(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let open = sinCurve(t, in: 0.10...0.78)
    let tongue = sinCurve(t, in: 0.18...0.82)
    var mouth = base
    mouth.openness = max(base.openness, open * 0.92)
    mouth.ovalWidth = 9.5
    mouth.ovalHeight = 8.2
    mouth.width = 11
    return OrbyIdleMicrobehaviorFrame(
      mouth: mouth,
      leftEyeHeightScale: 1 - 0.16 * open,
      rightEyeHeightScale: 1 - 0.14 * open,
      trackingFactor: 0.2,
      overlay: OrbyIdleMicroOverlay(tongueProgress: tongue)
    )
  }

  private static func bubbleBlow(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let open = sinCurve(t, in: 0.08...0.58)
    let float = max(0, (t - 0.25) / 0.75)
    var mouth = base
    mouth.openness = max(base.openness, open * 0.95)
    mouth.ovalWidth = 7.5
    mouth.ovalHeight = 8.6
    mouth.width = 8
    let bubbleR = CGFloat(6 + 9 * OrbyMiniVisualEasing.smoothstep(float))
    return OrbyIdleMicrobehaviorFrame(
      scriptedEyeOffset: CGSize(width: 1.5 * open, height: -0.5 * open),
      mouth: mouth,
      trackingFactor: 0.15,
      overlay: OrbyIdleMicroOverlay(
        bubbleCenter: CGPoint(x: 42, y: 42 - float * 22),
        bubbleRadius: bubbleR,
        bubbleOpacity: min(1, open * 1.45) * (1 - float * 0.68)
      )
    )
  }

  private static func cheekPuff(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let hold = sinCurve(t, in: 0.2...0.65)
    var mouth = base
    mouth.width = max(4, base.width * (1 - 0.58 * hold))
    mouth.lineHeight = max(1.8, base.lineHeight * (1 - 0.2 * hold))
    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.leftEyeHeightScale = 1 + 0.16 * hold
    frame.rightEyeHeightScale = 1 + 0.16 * hold
    frame.faceNudge = CGSize(width: 0, height: 1.3 * hold)
    frame.trackingFactor = 0
    frame.overlay = OrbyIdleMicroOverlay(puffScale: 1 + 0.075 * hold)
    return frame
  }

  private static func tinyYawn(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let yawn = sinCurve(t, in: 0.2...0.7)
    var mouth = base
    mouth.openness = yawn * 0.92
    mouth.ovalWidth = 7.2
    mouth.ovalHeight = 6 + 8 * yawn
    return OrbyIdleMicrobehaviorFrame(
      eyelidClosure: 0.40 + 0.50 * yawn,
      mouth: mouth,
      faceNudge: CGSize(width: 0, height: -1.3 * yawn),
      extraOrbScale: 1 + 0.024 * yawn,
      trackingFactor: 0
    )
  }

  private static func sleepyNod(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let nod = sinCurve(t, in: 0.15...0.55)
    let recover = sinCurve(t, in: 0.55...0.95)
    var frame = OrbyIdleMicrobehaviorFrame()
    frame.eyelidClosure = 0.34 + 0.62 * nod - 0.16 * recover
    frame.mouth = base
    frame.faceNudge = CGSize(width: 0, height: 4.2 * nod - 1.4 * recover)
    frame.trackingFactor = 0
    frame.faceTiltDegrees = -2.6 * nod
    return frame
  }

  private static func sparkleCatch(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let spark = sinCurve(t, in: 0.08...0.55)
    let glance = sinCurve(t, in: 0.1...0.65)
    var mouth = base
    mouth.cornerLift = max(base.cornerLift, 4.4 * spark)
    var frame = OrbyIdleMicrobehaviorFrame()
    frame.scriptedEyeOffset = CGSize(width: 5.4 * glance, height: -3.5 * glance)
    frame.mouth = mouth
    frame.trackingFactor = 0.1
    frame.faceTiltDegrees = 1.0 * spark
    frame.overlay = OrbyIdleMicroOverlay(
      sparkleOpacity: min(1, spark * 1.2),
      sparklePoint: CGPoint(x: 58, y: 20)
    )
    return frame
  }

  private static func sideEye(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let hold = sinCurve(t, in: 0.2...0.75)
    var mouth = base
    mouth.cornerLift = min(base.cornerLift, -2.4 * hold)
    mouth.width = base.width * (1 - 0.20 * hold)
    let h = CGFloat(hold)
    var frame = OrbyIdleMicrobehaviorFrame()
    frame.scriptedEyeOffset = CGSize(width: -7.4 * h, height: 0.5 * h)
    frame.mouth = mouth
    frame.leftEyeHeightScale = 1 - 0.36 * h
    frame.rightEyeHeightScale = 1 - 0.32 * h
    frame.faceTiltDegrees = -5.5 * hold
    frame.headTurnYExtra = -2.4 * hold
    frame.trackingFactor = 0
    return frame
  }

  private static func tinySneeze(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let sneeze: Double
    if t < 0.45 {
      sneeze = OrbyMiniVisualEasing.smoothstep(t / 0.45)
    } else {
      sneeze = 1 - OrbyMiniVisualEasing.smoothstep((t - 0.45) / 0.55)
    }
    var mouth = base
    mouth.openness = sneeze * 0.78
    mouth.ovalWidth = 7
    mouth.ovalHeight = 5.8
    return OrbyIdleMicrobehaviorFrame(
      eyelidClosure: 0.7 * sneeze,
      mouth: mouth,
      faceNudge: CGSize(width: 0, height: 3.6 * sneeze),
      trackingFactor: 0,
      overlay: OrbyIdleMicroOverlay(
        bubbleCenter: CGPoint(x: 41, y: 47),
        bubbleRadius: 3,
        bubbleOpacity: sneeze * 0.85 * (1 - t)
      )
    )
  }

  private static func pixelShiver(_ t: Double) -> OrbyIdleMicrobehaviorFrame {
    let phase = Int(t * 12) % 4
    let jitter = CGSize(
      width: phase == 0 ? -2.6 : (phase == 1 ? 2.6 : 0),
      height: phase == 2 ? 2.0 : (phase == 3 ? -1.8 : 0)
    )
    return OrbyIdleMicrobehaviorFrame(
      overlay: OrbyIdleMicroOverlay(faceJitter: jitter)
    )
  }

  /// A private anime-protagonist beat: sparkle eyes morph in, smug little smile, blush,
  /// faint delight tremble, 1–3 tiny glints — then everything morphs cleanly back out.
  /// Timeline (normalized over ~2.0s duration):
  ///   0.00–0.275  begin / anticipation → full reveal (sparkle "open", no hard swap)
  ///   0.275–0.725 hold: full anime eyes, smug smile, blush, sparkles, gentle tremble
  ///   0.725–1.00  morph back: tremble fades, eyes soften, smile relaxes, cursor-follow returns
  private static func animeSelfSatisfied(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    // Reveal envelope: ease in to 1 by 0.275, hold, ease back to 0 by 1.0.
    let reveal: Double
    if t < 0.275 {
      reveal = OrbyMiniVisualEasing.smoothstep(t / 0.275)
    } else if t < 0.725 {
      reveal = 1
    } else {
      reveal = 1 - OrbyMiniVisualEasing.smoothstep((t - 0.725) / 0.275)
    }

    // Proud, smug little closed smile (uses persistent morphing mouth — no swap).
    var mouth = base
    mouth.openness = 0
    mouth.width = base.width + (15.5 - base.width) * CGFloat(reveal)
    mouth.cornerLift = max(base.cornerLift, 4.0 * CGFloat(reveal))
    mouth.curvature = max(base.curvature, 0.7)

    // Delight tremble — small, mostly horizontal, fast, only across the hold window.
    var jitter = CGSize.zero
    if t > 0.30, t < 0.78 {
      let env = sin((t - 0.30) / 0.48 * .pi)          // 0→1→0 across the window
      let osc = sin(t * 2 * .pi * 22)                  // ~fast shimmer
      jitter = CGSize(width: CGFloat(osc * env * 1.1), height: CGFloat(sin(t * 2 * .pi * 18) * env * 0.4))
    }

    // Sparkles: appear ~0.22, fade by ~0.78.
    let sparkle: Double
    if t < 0.22 {
      sparkle = 0
    } else if t < 0.5 {
      sparkle = OrbyMiniVisualEasing.smoothstep((t - 0.22) / 0.28)
    } else if t < 0.78 {
      sparkle = 1
    } else {
      sparkle = 1 - OrbyMiniVisualEasing.smoothstep((t - 0.78) / 0.22)
    }

    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.scriptedEyeOffset = CGSize(width: 0, height: -0.6 * reveal) // sits ~1pt higher
    frame.faceNudge = CGSize(width: 0, height: -0.8 * reveal)
    frame.extraOrbScale = 1 + 0.006 * CGFloat(reveal)
    frame.extraWarmth = 0.12 * reveal
    frame.faceTiltDegrees = 0.6 * reveal
    frame.trackingFactor = max(0, 1 - reveal)   // freeze cursor-follow at peak, blend back
    frame.overlay = OrbyIdleMicroOverlay(
      faceJitter: jitter,
      animeEyeReveal: reveal,
      animeSparkleOpacity: sparkle
    )
    return frame
  }

  // MARK: - Stylized character beats

  /// Tiny cosmic detective: noir grading + venetian light bands, suspicious squint
  /// scanning the "floor" beneath himself, flat "hmm" mouth, slight downward lean.
  private static func noirDetective(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let rv = reveal(t, inEnd: 0.10, outStart: 0.85)

    // Suspicious squint — one eye a touch narrower near the end (skeptical).
    let skew = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.6) / 0.25, 0), 1))
    let leftScale = 1 - 0.50 * rv
    let rightScale = 1 - (0.50 + 0.12 * skew) * rv

    // Eyes scan the bottom arc: down-left → center → right → pause down-right → center.
    var scanX: CGFloat = 0
    if t < 0.30 {
      scanX = -4.6 * CGFloat(OrbyMiniVisualEasing.smoothstep(min(max((t - 0.10) / 0.20, 0), 1)))
    } else if t < 0.55 {
      let p = CGFloat(OrbyMiniVisualEasing.smoothstep((t - 0.30) / 0.25))
      scanX = -4.6 + 9.2 * p           // left → right
    } else if t < 0.78 {
      scanX = 4.6                       // pause down-right
    } else {
      scanX = 4.6 * CGFloat(1 - OrbyMiniVisualEasing.smoothstep((t - 0.78) / 0.22)) // → center side-eye
    }
    let lookDown: CGFloat = 3.4 * CGFloat(rv)

    // Flat "hmm" line — slightly downturned, asymmetric at the end.
    var mouth = base
    mouth.openness = 0
    mouth.curvature = 0.3
    mouth.width = base.width + (9.0 - base.width) * CGFloat(rv)
    mouth.lineHeight = max(1.8, base.lineHeight)
    mouth.cornerLift = min(base.cornerLift, -1.8 * CGFloat(rv) - 0.8 * CGFloat(skew) * CGFloat(rv))

    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.scriptedEyeOffset = CGSize(width: scanX * CGFloat(rv), height: lookDown)
    frame.leftEyeHeightScale = leftScale
    frame.rightEyeHeightScale = rightScale
    frame.faceNudge = CGSize(width: 0, height: 1.6 * rv)          // visual dip (not panel)
    frame.faceTiltDegrees = 3.0 * rv                              // lean to inspect floor
    frame.trackingFactor = max(0, 1 - rv)                         // suppress cursor-follow
    frame.overlay = OrbyIdleMicroOverlay(
      noirReveal: rv,
      noirBandPhase: t * 1.6,
      noirClueOpacity: (t > 0.34 && t < 0.7) ? sin((t - 0.34) / 0.36 * .pi) * 0.8 : 0
    )
    return frame
  }

  /// A small comet enters from outside the orb, crosses the internal sky, and exits.
  /// Orby reacts surprised at entry and exit and tracks it with a fascinated little "o".
  private static func cosmicCometWatch(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    // Comet visibility (incl. brief outside tails at entry/exit).
    let opacity: Double
    if t < 0.05 {
      opacity = OrbyMiniVisualEasing.smoothstep(t / 0.05)
    } else if t < 0.9 {
      opacity = 1
    } else {
      opacity = 1 - OrbyMiniVisualEasing.smoothstep((t - 0.9) / 0.1)
    }
    // Position along the entry→exit path (0 outside-left … 1 outside-right).
    let progress = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.05) / 0.9, 0), 1))

    // Two surprise beats: entry (~0.12) and exit (~0.85).
    let entrySurprise = bump(t, center: 0.14, halfWidth: 0.12)
    let exitSurprise = bump(t, center: 0.85, halfWidth: 0.12)
    let surprise = max(entrySurprise, exitSurprise)

    // Eyes widen and track the comet left → right.
    let trackX = CGFloat((progress * 2 - 1)) * 5.2
    let widen = 1 + 0.28 * surprise

    // Fascinated small "o".
    var mouth = base
    mouth.ovalWidth = 6.2
    mouth.ovalHeight = 6.6
    mouth.openness = max(base.openness, 0.42 + 0.30 * surprise)
    mouth.width = 7

    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.scriptedEyeOffset = CGSize(width: trackX, height: -1.0 - 0.8 * surprise)
    frame.leftEyeHeightScale = widen
    frame.rightEyeHeightScale = widen
    frame.trackingFactor = 0
    frame.headTurnYExtra = Double(trackX) * 0.5
    frame.overlay = OrbyIdleMicroOverlay(
      cometOpacity: opacity,
      cometProgress: progress
    )
    return frame
  }

  /// Tiny cosmic cat energy: stylized slit eyes, a smug little smile, a slow side glance.
  private static func catMode(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let rv = reveal(t, inEnd: 0.14, outStart: 0.78)
    let glance = sin(min(max((t - 0.2) / 0.6, 0), 1) * .pi) // one slow sideways glance

    // Smug small smile (persistent morphing mouth; no "3" view needed).
    var mouth = base
    mouth.openness = 0
    mouth.width = base.width + (13.0 - base.width) * CGFloat(rv)
    mouth.cornerLift = max(base.cornerLift, 3.4 * CGFloat(rv))
    mouth.curvature = max(base.curvature, 0.7)

    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.scriptedEyeOffset = CGSize(width: 3.0 * CGFloat(glance) * CGFloat(rv), height: 0)
    frame.faceTiltDegrees = 3.0 * rv
    frame.extraWarmth = 0.08 * rv
    frame.trackingFactor = max(0, 1 - rv)
    frame.overlay = OrbyIdleMicroOverlay(catEyeReveal: rv)
    return frame
  }

  /// A tiny black hole appears inside the sky, nibbles a star, and Orby recoils away from it.
  private static func blackHoleNibble(_ t: Double, base: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame {
    let strength = reveal(t, inEnd: 0.22, outStart: 0.85)
    let side: CGFloat = 1 // right side (deterministic; face shifts left)
    let starProgress = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.30) / 0.45, 0), 1))

    // Face recoils away from the hole (visual offset only — never the panel).
    let awayEnv = reveal(t, inEnd: 0.35, outStart: 0.75)
    let faceAwayX = -side * 5.0 * CGFloat(awayEnv)
    let faceAwayY = -2.0 * CGFloat(awayEnv)

    // Eyes widen; glance at the hole, then nervously away (a couple of beats).
    let lookAtHole = bump(t, center: 0.30, halfWidth: 0.16)
    let lookAway = max(bump(t, center: 0.55, halfWidth: 0.12), bump(t, center: 0.72, halfWidth: 0.12))
    let eyeX = side * 4.2 * CGFloat(lookAtHole) - side * 3.4 * CGFloat(lookAway)
    let widen = 1 + 0.26 * strength

    // Worried small "o".
    var mouth = base
    mouth.ovalWidth = 6.5
    mouth.ovalHeight = 7.0
    mouth.openness = max(base.openness, 0.34 + 0.16 * lookAtHole)
    mouth.width = 7
    mouth.cornerLift = min(base.cornerLift, -1.0 * CGFloat(strength))

    var frame = OrbyIdleMicrobehaviorFrame()
    frame.mouth = mouth
    frame.scriptedEyeOffset = CGSize(width: eyeX, height: -1.4 * strength)
    frame.leftEyeHeightScale = widen
    frame.rightEyeHeightScale = widen
    frame.faceNudge = CGSize(width: faceAwayX, height: faceAwayY)
    frame.extraWarmth = -0.06 * strength // cool/dim a touch
    frame.trackingFactor = 0
    frame.overlay = OrbyIdleMicroOverlay(
      blackHoleStrength: strength,
      blackHoleSide: side,
      blackHoleStarProgress: starProgress
    )
    return frame
  }

  /// A smooth 0→1→0 pulse centered at `center` with the given half-width.
  private static func bump(_ t: Double, center: Double, halfWidth: Double) -> Double {
    let d = abs(t - center)
    guard d < halfWidth else { return 0 }
    return 0.5 + 0.5 * cos(d / halfWidth * .pi)
  }

  private static func sinCurve(_ t: Double, in range: ClosedRange<Double>) -> Double {
    guard t >= range.lowerBound, t <= range.upperBound else { return 0 }
    let local = (t - range.lowerBound) / (range.upperBound - range.lowerBound)
    return sin(local * .pi)
  }
}
