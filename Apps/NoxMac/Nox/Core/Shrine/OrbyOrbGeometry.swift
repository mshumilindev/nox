import AppKit
import CoreGraphics

/// Circular Orby hit geometry (panel padding does not count as the orb).
enum OrbyOrbGeometry {
  static let orbDiameter: CGFloat = 76
  static let orbRadius: CGFloat = orbDiameter / 2
  static let hitTolerance: CGFloat = 3
  /// Extra layout margin so squash/stretch (up to ~1.10) and Zzz never clip the panel.
  static let visualBleedPadding: CGFloat = 6
  static let chromePadding: CGFloat = 14 + visualBleedPadding

  static func isCursorInsideOrb(panel: NSPanel) -> Bool {
    isScreenPointInsideOrb(NSEvent.mouseLocation, panel: panel)
  }

  static func isScreenPointInsideOrb(_ screenPoint: NSPoint, panel: NSPanel) -> Bool {
    guard let contentView = panel.contentView else { return false }
    let trackView = contentView.subviews.first ?? contentView
    let mouseInWindow = panel.convertPoint(fromScreen: screenPoint)
    let local = trackView.convert(mouseInWindow, from: nil)
    return isLocalPointInsideOrb(local, hostSize: trackView.bounds.size)
  }

  static func isLocalPointInsideOrb(_ point: CGPoint, hostSize: CGSize) -> Bool {
    let center = orbCenter(inHostSize: hostSize)
    let dx = point.x - center.x
    let dy = point.y - center.y
    return hypot(dx, dy) <= orbRadius + hitTolerance
  }

  static func orbCenter(inHostSize size: CGSize) -> CGPoint {
    CGPoint(x: size.width / 2, y: size.height / 2)
  }
}
