import CoreGraphics
import Foundation

/// Hello syllable flight + “Hello” hold (hello sub-progress 0…1 after smile hold).
enum OrbyLaunchGreetingSyllableTiming {
  // Syllables rise out of the mouth and assemble into "Hello" *above* the orb
  // (negative y is inside the chrome's top padding, clear of Orby's face).
  static let mouthLaunch = CGPoint(x: 38 + 4, y: 38 + 12)

  static let heLaunchProgress: Double = 0.06
  static let heArriveProgress: Double = 0.22
  static let heJoinPoint = CGPoint(x: 33, y: -9)

  static let lloLaunchProgress: Double = 0.26
  static let lloArriveProgress: Double = 0.36

  static var wordAssemblyEndProgress: Double {
    lloArriveProgress
  }

  static var wordHoldEndProgress: Double {
    wordAssemblyEndProgress
      + OrbyMiniVisualTiming.launchGreetingHelloWordHoldSeconds / OrbyMiniVisualTiming.launchGreetingHelloSeconds
  }

  static var wordFadeEndProgress: Double {
    min(
      wordHoldEndProgress
        + OrbyMiniVisualTiming.launchGreetingHelloFadeSeconds / OrbyMiniVisualTiming.launchGreetingHelloSeconds,
      1
    )
  }

  static let lloJoinPoint = CGPoint(x: 43.5, y: -9)
}
