import Foundation

/// Surface-form rules for Orby mini presentation (bubble vs fake notch).
enum OrbySurfaceFormBehavior {
  /// Launch Hello runs on manual bubble show only — not when docked in notch.
  static func allowsLaunchGreeting(_ form: OrbySurfaceForm) -> Bool {
    form != .notch
  }

  /// Sleep / wake ritual uses the same cursor-idle timer as bubble.
  static func allowsSleepCycle(_ form: OrbySurfaceForm) -> Bool {
    true
  }

  /// Idle microbehaviors schedule while awake in notch as well as bubble.
  static func allowsIdleMicrobehaviors(_ form: OrbySurfaceForm) -> Bool {
    true
  }

  /// Compact notch orb skips animated starfield/nebula (CPU).
  static func usesSimplifiedOrbMaterial(_ form: OrbySurfaceForm) -> Bool {
    form == .notch
  }

  /// Passive internal meteors stay bubble-only.
  static func usesAmbientSkyMeteors(_ form: OrbySurfaceForm) -> Bool {
    form != .notch
  }

  /// Menu-bar bezel sampling is bubble-only.
  static func samplesBezelFromBackground(_ form: OrbySurfaceForm) -> Bool {
    form != .notch
  }
}
