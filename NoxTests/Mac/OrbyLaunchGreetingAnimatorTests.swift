import Foundation
import CoreGraphics
import Testing
@testable import Nox

@Suite("Orby launch greeting")
struct OrbyLaunchGreetingAnimatorTests {
  @Test("Mouth endpoints match smile targets")
  func mouthEndpoints() {
    let start = OrbyLaunchGreetingAnimator.mouth(progress: 0)
    let end = OrbyLaunchGreetingAnimator.mouth(progress: 1)
    #expect(start.width == OrbyLaunchGreetingMouth.smileSeed.width)
    #expect(start.cornerLift == OrbyLaunchGreetingMouth.smileSeed.cornerLift)
    #expect(end.width == OrbyLaunchGreetingMouth.smileSettle.width)
  }

  @Test("llo syllable is more open than he")
  func lloMoreOpenThanHe() {
    let he = OrbyLaunchGreetingMouth.helloHe
    let llo = OrbyLaunchGreetingMouth.helloLlo
    #expect(llo.openness > he.openness)
    #expect(llo.ovalHeight > he.ovalHeight)
  }

  @Test("Hello visemes use readable open carrier shapes")
  func helloVisemesAreReadable() {
    let he = OrbyLaunchGreetingAnimator.mouth(progress: globalProgress(hello: 0.22))
    let llo = OrbyLaunchGreetingAnimator.mouth(progress: globalProgress(hello: 0.50))
    #expect(he.ovalHeight >= 9)
    #expect(he.ovalWidth >= 14)
    #expect(llo.ovalHeight > llo.ovalWidth)
    #expect(llo.openness > 0.5)
  }

  @Test("Hello mouth goes he then llo without a narrow L robot step")
  func heThenLloMouth() {
    let he = OrbyLaunchGreetingAnimator.mouth(progress: globalProgress(hello: 0.24))
    let llo = OrbyLaunchGreetingAnimator.mouth(progress: globalProgress(hello: 0.44))
    #expect(he.openness > 0.45)
    #expect(llo.openness > he.openness * 0.85)
    #expect(llo.ovalWidth > 9)
  }

  @Test("Syllables hold assembled Hello for two seconds")
  func helloWordHoldDuration() {
    let hold = OrbyMiniVisualTiming.launchGreetingHelloWordHoldSeconds
    let span = OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress
      - OrbyLaunchGreetingSyllableTiming.wordAssemblyEndProgress
    let hello = OrbyMiniVisualTiming.launchGreetingHelloSeconds
    #expect(abs(span * hello - hold) < 0.02)
  }

  private func globalProgress(hello: Double) -> Double {
    let hold = OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds
    let helloDur = OrbyMiniVisualTiming.launchGreetingHelloSeconds
    let total = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    return (hold + hello * helloDur) / total
  }

  @Test("Greeting holds smile before Hello")
  func smileHoldBeforeHello() {
    let beforeProgress = (OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds - 0.05)
      / OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let beforeHello = OrbyLaunchGreetingAnimator.mouth(progress: beforeProgress)
    let smile = OrbyLaunchGreetingMouth.smileGreeting
    #expect(beforeHello.width == smile.width)
    #expect(beforeHello.openness == smile.openness)
    #expect(OrbyLaunchGreetingAnimator.helloProgress(from: beforeProgress) == 0)
  }

  @Test("Smile lift arrives before full width")
  func smileLiftArrivesBeforeFullWidth() {
    let earlyProgress = 0.18 / OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let mouth = OrbyLaunchGreetingAnimator.mouth(progress: earlyProgress)
    #expect(mouth.cornerLift > OrbyLaunchGreetingMouth.smileSeed.cornerLift)
    #expect(mouth.width < OrbyLaunchGreetingMouth.smileGreeting.width)
  }

  @Test("Hello begins after two second smile hold")
  func helloStartsAfterSmileHold() {
    let total = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let before = (OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds - 0.05) / total
    let after = (OrbyMiniVisualTiming.launchGreetingSmileHoldSeconds + 0.10) / total
    #expect(OrbyLaunchGreetingAnimator.helloProgress(from: before) == 0)
    #expect(OrbyLaunchGreetingAnimator.helloProgress(from: after) > 0)
  }

  @Test("Appear scale settles to 1")
  func appearScaleSettles() {
    let early = OrbyLaunchGreetingAnimator.appearScale(progress: 0.05)
    let late = OrbyLaunchGreetingAnimator.appearScale(progress: 1)
    #expect(early < 1.03)
    #expect(abs(late - 1) < 0.02)
  }
}
