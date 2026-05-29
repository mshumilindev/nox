import SwiftUI
import NoxDesignCore

/// Static Orby preview for the menu bar — the *exact same* orb chrome + face used by
/// the floating ball (`OrbyFaceView`), rendered from a frozen presentation so there
/// are no animations, breathing, blinks, or idle microbehaviours.
struct OrbyMenuBarMarkView: View {
  let mood: OrbyMood
  let intensity: OrbyEmotionIntensity
  let emotion: OrbyEmotionAppearance
  let moodTitle: String

  /// Displayed orb diameter in the menu row.
  private let displayDiameter: CGFloat = 36

  private var scale: CGFloat { displayDiameter / OrbyOrbGeometry.orbDiameter }
  private var footprint: CGFloat {
    (OrbyOrbGeometry.orbDiameter + OrbyOrbGeometry.chromePadding * 2) * scale
  }

  private var presentation: OrbyMiniVisualPresentation {
    .menuBarStatic(mood: mood, intensity: intensity, emotion: emotion)
  }

  var body: some View {
    OrbyFaceView(presentation: presentation)
      .scaleEffect(scale)
      .frame(width: footprint, height: footprint)
      .accessibilityLabel("Orby, \(moodTitle)")
  }
}

extension OrbyMiniVisualPresentation {
  /// A fully frozen presentation: awake, no ambient blink, no idle micro/overlays,
  /// no breathing/drag/dazed effects. Used for static previews (e.g. the menu bar).
  static func menuBarStatic(
    mood: OrbyMood,
    intensity: OrbyEmotionIntensity,
    emotion: OrbyEmotionAppearance
  ) -> OrbyMiniVisualPresentation {
    OrbyMiniVisualPresentation(
      resolvedMood: mood,
      intensity: intensity,
      phase: .awake,
      emotion: emotion,
      cursorEyeOffset: .zero,
      scriptedEyeOffset: .zero,
      dragFaceLagOffset: .zero,
      dragDeformation: OrbyDragDeformationSnapshot(),
      dragFaceDeformationStrength: 0,
      headTurnXDegrees: 0,
      headTurnYDegrees: 0,
      eyeTrackingFactor: 0,
      eyelidClosure: 0,
      bezelOnDarkBackground: true,
      backgroundLuminance: 0.12,
      breathingScale: 1,
      zzzOpacity: 0,
      dazedHaloOpacity: 0,
      orbScale: 1,
      isExcited: false,
      isDragging: false,
      allowsAmbientBlink: false,
      ambientBlinkInterval: 3...6,
      idleMicro: nil,
      idleMicroOverlay: OrbyIdleMicroOverlay(),
      idleFaceNudge: .zero,
      idleFaceTiltDegrees: 0,
      idleExtraOrbScale: 1,
      wakeMouthCrossfade: 1,
      cheekBlushStrength: 0,
      sleepBreath: 0,
      dayNightBlend: 0
    )
  }
}

#Preview {
  OrbyMenuBarMarkView(
    mood: .neutral,
    intensity: .normal,
    emotion: .neutralDefault,
    moodTitle: "Neutral"
  )
  .padding()
  .preferredColorScheme(.dark)
}
