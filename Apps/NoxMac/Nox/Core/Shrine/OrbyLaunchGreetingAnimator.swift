import Foundation
import CoreGraphics

/// Deterministic silent “Hello” mouth / eye / appear timeline.
enum OrbyLaunchGreetingAnimator {
  private struct MouthKeyframe {
    let progress: Double
    let mouth: OrbyMouthParameters
  }

  private static let mouthKeyframes: [MouthKeyframe] = [
    MouthKeyframe(progress: 0.00, mouth: OrbyLaunchGreetingMouth.smileGreeting),
    MouthKeyframe(progress: 0.06, mouth: OrbyLaunchGreetingMouth.smileGreeting),
    // "He" opens, then morphs *continuously* into "llo" with no held plateau between them.
    MouthKeyframe(progress: 0.18, mouth: OrbyLaunchGreetingMouth.helloHe),
    MouthKeyframe(progress: 0.40, mouth: OrbyLaunchGreetingMouth.helloLlo),
    MouthKeyframe(progress: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress, mouth: OrbyLaunchGreetingMouth.helloLlo),
    MouthKeyframe(progress: min(OrbyLaunchGreetingSyllableTiming.wordFadeEndProgress + 0.04, 0.98), mouth: OrbyLaunchGreetingMouth.smileSettle),
    MouthKeyframe(progress: 1.00, mouth: OrbyLaunchGreetingMouth.smileSettle)
  ]

  static func mouth(progress: Double) -> OrbyMouthParameters {
    let hello = helloProgress(from: progress)
    guard hello > 0 else {
      return smileHoldMouth(progress: progress)
    }
    return interpolateMouth(progress: hello)
  }

  /// Reduced tracking early; full follow by end of greeting.
  static func eyeTrackingFactor(progress: Double) -> Double {
    let p = min(max(progress, 0), 1)
    let hello = helloProgress(from: p)
    if hello <= 0 {
      return 0.18
    }
    if hello < 0.59 {
      return 0.22 + hello * 0.14
    }
    let t = (hello - 0.59) / 0.41
    return 0.30 + OrbyMiniVisualEasing.smoothstep(t) * 0.70
  }

  /// Subtle appear bounce 0.96 → 1.02 → 1.0 in the first ~0.35 s.
  static func appearScale(progress: Double) -> CGFloat {
    let duration = OrbyMiniVisualTiming.launchGreetingAppearSeconds
    let total = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let t = min(max(progress * total / duration, 0), 1)
    if t < 0.55 {
      let u = OrbyMiniVisualEasing.smoothstep(t / 0.55)
      return CGFloat(0.96 + u * 0.06)
    }
    let u = OrbyMiniVisualEasing.smoothstep((t - 0.55) / 0.45)
    return CGFloat(1.02 - u * 0.02)
  }

  /// A tiny friendly breathing lift during the pre-Hello smile hold.
  static func smileHoldScale(progress: Double) -> CGFloat {
    let smileHoldEnd = OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds
      / OrbyMiniVisualTiming.launchGreetingDurationSeconds
    guard progress < smileHoldEnd else { return 1 }
    let cycle = sin(progress * .pi * 2.2)
    return CGFloat(1 + max(0, cycle) * 0.012)
  }

  /// Smile formation during the 2 s hold. Lift and curvature arrive first; width follows.
  static func smileHoldMouth(progress: Double) -> OrbyMouthParameters {
    let total = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let seconds = min(max(progress, 0), 1) * total
    let hold = OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds
    let t = min(max(seconds / hold, 0), 1)
    let liftT = OrbyMiniVisualEasing.smoothstep(min(max(t / 0.28, 0), 1))
    let widthT = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.18) / 0.54, 0), 1))
    let settleT = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.72) / 0.28, 0), 1))
    let seed = OrbyLaunchGreetingMouth.smileSeed
    let full = OrbyLaunchGreetingMouth.smileGreeting
    var mouth = OrbyMouthParameters(
      width: seed.width + (full.width - seed.width) * CGFloat(widthT),
      lineHeight: full.lineHeight,
      cornerLift: seed.cornerLift + (full.cornerLift - seed.cornerLift) * CGFloat(liftT),
      curvature: seed.curvature + (full.curvature - seed.curvature) * CGFloat(liftT),
      openness: 0,
      ovalWidth: full.ovalWidth,
      ovalHeight: full.ovalHeight
    )
    let breath = sin(t * .pi * 2.0)
    mouth.cornerLift += CGFloat(max(0, breath)) * 0.35 * CGFloat(1 - settleT * 0.35)
    return mouth
  }

  static func scriptedEyeOffset(progress: Double) -> CGSize {
    let hello = helloProgress(from: progress)
    guard hello > 0 else { return .zero }
    let he = pulse(hello, start: 0.08, peak: 0.20, end: 0.38)
    let llo = pulse(hello, start: 0.30, peak: 0.42, end: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress)
    return CGSize(
      width: CGFloat(he * 1.2 + llo * 0.9),
      height: CGFloat(-he * 0.45 + llo * 0.5)
    )
  }

  static func headTurnX(progress: Double) -> Double {
    let hello = helloProgress(from: progress)
    guard hello > 0 else { return 0 }
    let he = pulse(hello, start: 0.08, peak: 0.20, end: 0.36)
    let llo = pulse(hello, start: 0.30, peak: 0.42, end: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress)
    return -3.0 * he + 2.0 * llo
  }

  static func headTurnY(progress: Double) -> Double {
    let hello = helloProgress(from: progress)
    guard hello > 0 else { return 0 }
    let he = pulse(hello, start: 0.08, peak: 0.20, end: 0.36)
    let llo = pulse(hello, start: 0.30, peak: 0.42, end: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress)
    return 3.0 * he + 1.4 * llo
  }

  static func helloPulseScale(progress: Double) -> CGFloat {
    let hello = helloProgress(from: progress)
    guard hello > 0 else { return 1 }
    let he = pulse(hello, start: 0.08, peak: 0.20, end: 0.36)
    let llo = pulse(hello, start: 0.30, peak: 0.42, end: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress)
    return CGFloat(1 + he * 0.02 + llo * 0.018)
  }

  static func helloProgress(from progress: Double) -> Double {
    let total = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let helloStart = OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds
    let helloDuration = OrbyMiniVisualTiming.launchGreetingHelloSeconds
    let seconds = min(max(progress, 0), 1) * total
    guard seconds > helloStart else { return 0 }
    return min(max((seconds - helloStart) / helloDuration, 0), 1)
  }

  private static func interpolateMouth(progress: Double) -> OrbyMouthParameters {
    let p = min(max(progress, 0), 1)
    guard let first = mouthKeyframes.first else { return OrbyLaunchGreetingMouth.smileGreeting }
    if p <= first.progress { return first.mouth }
    guard let last = mouthKeyframes.last else { return first.mouth }
    if p >= last.progress { return last.mouth }

    var lower = first
    var upper = last
    for index in mouthKeyframes.indices {
      let frame = mouthKeyframes[index]
      if frame.progress <= p { lower = frame }
      if frame.progress >= p {
        upper = frame
        break
      }
    }

    if lower.progress == upper.progress { return lower.mouth }
    let local = (p - lower.progress) / (upper.progress - lower.progress)
    let eased = OrbyMiniVisualEasing.smoothstep(local)
    return OrbyMouthParameters.interpolated(from: lower.mouth, to: upper.mouth, progress: eased)
  }

  private static func pulse(_ progress: Double, start: Double, peak: Double, end: Double) -> Double {
    guard progress > start, progress < end else { return 0 }
    if progress <= peak {
      return OrbyMiniVisualEasing.smoothstep((progress - start) / (peak - start))
    }
    return 1 - OrbyMiniVisualEasing.smoothstep((progress - peak) / (end - peak))
  }
}
