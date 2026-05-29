import Foundation

/// Viseme-like mouth targets for silent “Hello” (one morphing mouth; not separate views).
enum OrbyLaunchGreetingMouth {
  /// First visible mouth in the smile hold: already curved, not a widened flat bar.
  static let smileSeed = OrbyMouthParameters(
    width: 11.5,
    lineHeight: 2.5,
    cornerLift: 3.6,
    curvature: 0.78,
    openness: 0,
    ovalWidth: 7,
    ovalHeight: 5
  )

  static let smileGreeting = OrbyMouthParameters(
    width: 16,
    lineHeight: 2.5,
    cornerLift: 6.0,
    curvature: 0.82,
    openness: 0,
    ovalWidth: 7,
    ovalHeight: 5
  )

  /// Single “he” syllable — one open beat (not HEH then wider EH).
  static let helloHe = OrbyMouthParameters(
    width: 16.5,
    lineHeight: 3.0,
    cornerLift: 2.6,
    curvature: 0.62,
    openness: 0.62,
    ovalWidth: 15.5,
    ovalHeight: 9.5,
    verticalOffset: 0.6
  )

  /// Second syllable “llo” — one morph target (not separate L then OH robot steps).
  static let helloLlo = OrbyMouthParameters(
    width: 11.5,
    lineHeight: 3.1,
    cornerLift: 0.35,
    curvature: 0.62,
    openness: 0.78,
    ovalWidth: 10.8,
    ovalHeight: 11.2,
    verticalOffset: 0.75
  )

  static let smileSettle = OrbyMouthParameters(
    width: 15,
    lineHeight: 2.4,
    cornerLift: 4.6,
    curvature: 0.76,
    openness: 0,
    ovalWidth: 7,
    ovalHeight: 5
  )
}
