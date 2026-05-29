import CoreGraphics
import Foundation

enum OrbyMeteorColor: Equatable {
  case paleLavender
  case paleCyan
  case paleRose
}

/// Single fast streak inside Orby's internal sky (not a microbehavior).
struct OrbyMeteorEvent: Equatable, Identifiable {
  let id: UUID
  let startedAt: TimeInterval
  let duration: TimeInterval
  /// Normalized orb space: center (0,0), radius 1 = orb edge.
  let start: CGPoint
  let end: CGPoint
  let headSize: CGFloat
  let tailLength: CGFloat
  let tailWidth: CGFloat
  let color: OrbyMeteorColor
  let peakOpacity: CGFloat
}

/// Rare cluster of meteors sharing a radiant direction.
struct OrbyPerseidShowerEvent: Equatable, Identifiable {
  let id: UUID
  let startedAt: TimeInterval
  let duration: TimeInterval
  let meteors: [OrbyMeteorEvent]
  let radiant: CGPoint
}

/// Render-ready meteor snapshot for one frame (orb-local coordinates, center origin).
struct OrbyAmbientMeteorRenderItem: Equatable {
  var head: CGPoint
  var tailEnd: CGPoint
  var headSize: CGFloat
  var tailWidth: CGFloat
  var headOpacity: Double
  var tailOpacity: Double
  var color: OrbyMeteorColor
}

enum OrbyAmbientSkyEventKind: Equatable {
  case meteor(OrbyMeteorEvent)
  case perseidShower(OrbyPerseidShowerEvent)
}
