import CoreGraphics
import SwiftUI

/// Hard drop shadow for Orby eyes and mouth (no blur — offset duplicate).
enum OrbyFaceShadowStyle {
  /// Light falls toward the bottom-right of the orb.
  static let offset = CGSize(width: 1.15, height: 1.35)
  static let color = Color(red: 0.11, green: 0.05, blue: 0.20).opacity(0.44)
}
