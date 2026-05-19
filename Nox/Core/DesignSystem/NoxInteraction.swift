import AppKit
import SwiftUI

/// macOS-native press feedback without shrinking the hit region.
struct NoxBorderlessPressStyle: ButtonStyle {
  var pressedOpacity: Double = 0.78

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? pressedOpacity : 1)
      .noxPointerCursor()
  }
}

extension ButtonStyle where Self == NoxBorderlessPressStyle {
  static var noxBorderless: NoxBorderlessPressStyle { NoxBorderlessPressStyle() }
}

extension View {
  /// Pointing-hand cursor on macOS for clickable controls.
  func noxPointerCursor(_ enabled: Bool = true) -> some View {
    onHover { inside in
      guard enabled else { return }
      if inside {
        NSCursor.pointingHand.set()
      } else {
        NSCursor.arrow.set()
      }
    }
  }
}
