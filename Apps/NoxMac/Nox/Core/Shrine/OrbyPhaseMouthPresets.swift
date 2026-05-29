import Foundation

/// Fixed mouth shapes for phase transitions — keep compositor and settle crossfade in sync.
enum OrbyPhaseMouthPresets {
  static let hoverExcited = OrbyMouthParameters(openness: 1, ovalWidth: 9, ovalHeight: 9)
}
