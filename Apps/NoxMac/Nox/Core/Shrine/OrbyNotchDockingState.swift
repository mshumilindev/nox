import CoreGraphics
import Foundation

/// Tunable fake notch geometry (16-inch MacBook Pro M4 class defaults).
struct FakeNotchGeometryConfig: Equatable {
  var estimatedRealNotchWidth: CGFloat = 190
  /// Just wide enough to contain Orby with small padding.
  var fakeNotchWidth: CGFloat = 34
  /// Matches the visible depth of the real MacBook Pro 16" M4 notch.
  var fakeNotchHeight: CGFloat = 32
  /// Gap is zero so the fake notch sits flush against the real notch.
  var fakeNotchGapFromRealNotch: CGFloat = 0
  var fakeNotchTopMargin: CGFloat = 0
  var fakeNotchCornerRadius: CGFloat = 15
}

/// Active surface form for Software Shrine mini Orby on macOS.
enum OrbySurfaceForm: Equatable {
  case bubble
  case notch
}

/// Drag substate for fake Dynamic Notch docking / undocking.
enum OrbyDockingDragState: Equatable {
  case none
  case bubbleDraggingNearNotch(proximity: CGFloat)
  case dockingPreview(proximity: CGFloat)
  case dockedInNotch
  case notchPullingOut(distance: CGFloat, tension: CGFloat)
  case undockedDuringDrag
}

/// Fake notch capsule appearance — purple only before drop; black when docked.
enum FakeNotchVisualState: Equatable {
  case hidden
  case dockingPreview(proximity: CGFloat)
  case docked
  case undockResistance(tension: CGFloat)
}

/// Render + interaction constants for fake notch docking (tuned for 16-inch MacBook Pro M4 class).
enum OrbyNotchDockingMetrics {
  static var geometry = FakeNotchGeometryConfig()

  static var estimatedRealNotchWidth: CGFloat { geometry.estimatedRealNotchWidth }
  static var fakeNotchGapFromRealNotch: CGFloat { geometry.fakeNotchGapFromRealNotch }
  static var fakeNotchWidth: CGFloat { geometry.fakeNotchWidth }
  static var fakeNotchHeight: CGFloat { geometry.fakeNotchHeight }
  static var fakeNotchTopMargin: CGFloat { geometry.fakeNotchTopMargin }
  static var fakeNotchCornerRadius: CGFloat { geometry.fakeNotchCornerRadius }

  static var fakeNotchCapsuleWidth: CGFloat { fakeNotchWidth }
  static var fakeNotchCapsuleHeight: CGFloat { fakeNotchHeight }

  /// Compact Notch Orby diameter (~10% smaller than prior 24 pt).
  static let notchOrbyDiameter: CGFloat = 22
  static var notchOrbyMaxDiameter: CGFloat { fakeNotchHeight - 8 }

  /// Compact Notch Orby vs 76 pt Bubble Orby.
  static var dockedOrbScale: CGFloat { notchOrbyDiameter / OrbyOrbGeometry.orbDiameter }
  /// Dock preview shrinks toward ~38 pt before settling to notch size on drop.
  static let previewOrbScaleMin: CGFloat = 38 / OrbyOrbGeometry.orbDiameter

  static let undockSoftPullDistance: CGFloat = 45
  static let undockStrongPullDistance: CGFloat = 95
  static let undockDetachThreshold: CGFloat = 160

  static let topCaptureBandHeight: CGFloat = 280
  static let notchCorridorHalfWidth: CGFloat = 640

  static let dropZoneHorizontalPad: CGFloat = 24
  static let dropZoneVerticalPad: CGFloat = 18

  static let dockPreviewFadeInSeconds: TimeInterval = 0.18
  static let dockSettleSeconds: TimeInterval = 0.28
  static let undockRetractSeconds: TimeInterval = 0.28
  static let undockDetachPopSeconds: TimeInterval = 0.18
  static let fakeNotchCollapseSeconds: TimeInterval = 0.22
}

struct OrbyNotchLayout: Equatable {
  let screenFrame: CGRect
  let fakeNotchFrame: CGRect
  let captureZone: CGRect
  let dropZone: CGRect
  let notchAnchor: CGPoint
  /// Horizontal offset from capsule center to Orby center (negative = leftward).
  let orbyXOffsetFromCapsuleCenter: CGFloat

  var isAvailable: Bool { !fakeNotchFrame.isEmpty }
}
