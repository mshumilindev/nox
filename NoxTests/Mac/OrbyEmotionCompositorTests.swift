import Foundation
import Testing
import NoxCore
@testable import Nox

@Test func orbyCompositorNeutralPassiveMutedCuriousEyeHeights() {
  let cases: [(OrbyMood, CGFloat, CGFloat)] = [
    (.neutral, 9.5, 7.5),
    (.passive, 8.5, 6.8),
    (.muted, 8.0, 6.5),
    (.curious, 10.5, 8.5)
  ]
  for (mood, leftH, rightH) in cases {
    let appearance = OrbyEmotionCompositor.compose(
      mood: mood,
      intensity: .normal,
      phase: .awake,
      eyelidClosure: 0,
      isExcited: false
    )
    #expect(appearance.leftEye.height == leftH)
    #expect(appearance.rightEye.height == rightH)
  }
}

@Test func awakeMoodsShareCanonicalEyeLayout() {
  let moods: [OrbyMood] = [
    .neutral, .passive, .muted, .focused, .deepFocus, .pleased, .curious, .thinking,
    .concerned, .skeptical, .annoyed, .alarmed, .sleepy, .tired, .disconnected,
    .overloaded, .nightWatch
  ]
  let spacing = OrbyEmotionAppearance.canonicalEyeSpacing
  let width = OrbyEmotionAppearance.canonicalEyeWidth
  for mood in moods {
    let appearance = OrbyEmotionCompositor.compose(
      mood: mood,
      intensity: .normal,
      phase: .awake,
      eyelidClosure: 0,
      isExcited: false
    )
    #expect(appearance.eyeSpacing == spacing)
    #expect(appearance.leftEye.width == width)
    #expect(appearance.rightEye.width == width)
    #expect(appearance.leftEye.horizontalShift == 0)
    #expect(appearance.rightEye.horizontalShift == 0)
  }
}

@Test func orbyCompositorHoverExcitedSurprisedMouth() {
  let appearance = OrbyEmotionCompositor.compose(
    mood: .neutral,
    intensity: .normal,
    phase: .hoverExcited,
    eyelidClosure: 0,
    isExcited: true
  )
  #expect(appearance.mouth.openness >= 0.95)
  #expect(appearance.mouth.ovalWidth >= 8)
  #expect(appearance.mouth.ovalHeight >= appearance.mouth.ovalWidth * 0.9)
  #expect(appearance.blinkIntervalScale == 0)
}

@Test func orbyCompositorAnnoyedStrongSteam() {
  let appearance = OrbyEmotionCompositor.compose(
    mood: .annoyed,
    intensity: .strong,
    phase: .awake,
    eyelidClosure: 0,
    isExcited: false
  )
  #expect(appearance.tint.redShift > 0.1)
  if case .steamPuffs(let n) = appearance.overlayParticles {
    #expect(n >= 1)
  } else {
    Issue.record("Expected steam puffs")
  }
}

@Test func orbyCompositorLaunchGreetingEmitsHelloSyllablesDuringSpeech() {
  let appearance = OrbyEmotionCompositor.compose(
    mood: .neutral,
    intensity: .normal,
    phase: .launchGreeting(progress: 0.68),
    eyelidClosure: 0,
    isExcited: false
  )
  if case .helloSyllables(let progress) = appearance.overlayParticles {
    #expect(progress > 0)
  } else {
    Issue.record("Expected Hello syllable particles")
  }
}

@Test func orbyCompositorLaunchGreetingHasNoSyllablesDuringSmileHold() {
  let appearance = OrbyEmotionCompositor.compose(
    mood: .neutral,
    intensity: .normal,
    phase: .launchGreeting(progress: 0.20),
    eyelidClosure: 0,
    isExcited: false
  )
  #expect(appearance.overlayParticles == .none)
}

@Test func orbyMoodOverloadedWhenManySignals() {
  let input = ShrineMoodInputs(
    presence: .active,
    idleSeconds: 0,
    isUserIdle: false,
    pauseState: .active,
    capabilities: NoxCapabilityState(
      accessibilityGranted: true,
      screenRecordingGranted: true,
      appAwarenessAvailable: true,
      windowAwarenessAvailable: true,
      interactionSignalsAvailable: true
    ),
    focusAnalysis: nil,
    soundsMuted: false,
    overloadSignalCount: 4,
    hasSystemContradiction: false,
    hasUrgentIntervention: false,
    recentDismissCount: 0
  )
  #expect(ShrineMoodResolver.resolve(input) == .overloaded)
}

@Test func orbyMoodSkepticalOnSecondDismiss() {
  let input = ShrineMoodInputs(
    presence: .active,
    idleSeconds: 0,
    isUserIdle: false,
    pauseState: .active,
    capabilities: NoxCapabilityState(
      accessibilityGranted: true,
      screenRecordingGranted: true,
      appAwarenessAvailable: true,
      windowAwarenessAvailable: true,
      interactionSignalsAvailable: true
    ),
    focusAnalysis: nil,
    soundsMuted: false,
    overloadSignalCount: 0,
    hasSystemContradiction: false,
    hasUrgentIntervention: false,
    recentDismissCount: 2
  )
  #expect(ShrineMoodResolver.resolve(input) == .skeptical)
}
