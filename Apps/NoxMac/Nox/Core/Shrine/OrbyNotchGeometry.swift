import AppKit
import CoreGraphics

/// Built-in MacBook notch detection and fake Dynamic Notch placement (left of real notch).
enum OrbyNotchGeometry {
  static func layout(for screen: NSScreen) -> OrbyNotchLayout? {
    guard isNotchedBuiltInDisplay(screen) else { return nil }

    let frame = screen.frame
    let topY = frame.maxY
    let notchCenterX = frame.midX

    let orbyWidth = OrbyNotchDockingMetrics.fakeNotchWidth
    // Match the real notch depth from safeAreaInsets when available.
    let capsuleH: CGFloat
    if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
      capsuleH = screen.safeAreaInsets.top
    } else {
      capsuleH = OrbyNotchDockingMetrics.fakeNotchHeight
    }
    let topMargin = OrbyNotchDockingMetrics.fakeNotchTopMargin
    let estimatedHalf = OrbyNotchDockingMetrics.estimatedRealNotchWidth / 2

    // Orby sits just left of the real notch's estimated left edge.
    let orbyAreaRightEdge = notchCenterX - estimatedHalf
    let orbyAreaLeftEdge = orbyAreaRightEdge - orbyWidth
    let orbyCenterX = orbyAreaLeftEdge + orbyWidth / 2
    let fakeNotchY = topY - capsuleH - topMargin

    // Extend the capsule rightward all the way to the real notch center.
    // Both are black when docked, so the overlap is invisible — no gap possible.
    let capsuleRightEdge = notchCenterX
    let totalCapsuleW = capsuleRightEdge - orbyAreaLeftEdge

    let fakeFrame = CGRect(
      x: orbyAreaLeftEdge,
      y: fakeNotchY,
      width: totalCapsuleW,
      height: capsuleH
    )

    guard fakeFrame.minX >= frame.minX + 8,
          fakeFrame.maxX <= frame.maxX - 8,
          fakeFrame.width > 0,
          fakeFrame.height > 0 else {
      return nil
    }

    let corridorHalfWidth = OrbyNotchDockingMetrics.notchCorridorHalfWidth
    let topBand = OrbyNotchDockingMetrics.topCaptureBandHeight
    let captureZone = CGRect(
      x: notchCenterX - corridorHalfWidth,
      y: topY - topBand,
      width: corridorHalfWidth * 2,
      height: topBand
    )

    let dropZone = fakeFrame.insetBy(
      dx: -OrbyNotchDockingMetrics.dropZoneHorizontalPad,
      dy: -OrbyNotchDockingMetrics.dropZoneVerticalPad
    )

    return OrbyNotchLayout(
      screenFrame: frame,
      fakeNotchFrame: fakeFrame,
      captureZone: captureZone,
      dropZone: dropZone,
      notchAnchor: CGPoint(x: orbyCenterX, y: fakeFrame.midY),
      orbyXOffsetFromCapsuleCenter: orbyCenterX - fakeFrame.midX
    )
  }

  static func layout(forScreenContaining point: NSPoint) -> OrbyNotchLayout? {
    guard let screen = screen(containing: point) else { return nil }
    return layout(for: screen)
  }

  static func isCursorInNotchCaptureCorridor(cursor: NSPoint, on screen: NSScreen) -> Bool {
    guard isNotchedBuiltInDisplay(screen) else { return false }
    let frame = screen.frame
    guard frame.contains(cursor) else { return false }
    let topBand = OrbyNotchDockingMetrics.topCaptureBandHeight
    let isNearTop = cursor.y >= frame.maxY - topBand
    let isNearNotchX = abs(cursor.x - frame.midX) <= OrbyNotchDockingMetrics.notchCorridorHalfWidth
    return isNearTop && isNearNotchX
  }

  static func proximity(from orbCenter: NSPoint, cursor: NSPoint, layout: OrbyNotchLayout) -> CGFloat {
    max(proximityToAnchor(from: orbCenter, layout: layout), proximityToAnchor(from: cursor, layout: layout))
  }

  static func proximity(from point: NSPoint, layout: OrbyNotchLayout) -> CGFloat {
    proximityToAnchor(from: point, layout: layout)
  }

  static func isInCaptureZone(orbCenter: NSPoint, layout: OrbyNotchLayout) -> Bool {
    layout.captureZone.contains(orbCenter)
  }

  static func isInCaptureZone(cursor: NSPoint, layout: OrbyNotchLayout) -> Bool {
    layout.captureZone.contains(cursor)
  }

  static func isInDropZone(point: NSPoint, layout: OrbyNotchLayout) -> Bool {
    layout.dropZone.contains(point)
  }

  static func isInDropZone(orbCenter: NSPoint, layout: OrbyNotchLayout) -> Bool {
    isInDropZone(point: orbCenter, layout: layout)
  }

  /// Monotonic outward visual offset while pulling Notch Orby before detach.
  static func undockVisualOffset(anchor: CGPoint, cursor: CGPoint, pullDistance: CGFloat) -> CGSize {
    guard pullDistance > 0.5 else { return .zero }
    let threshold = OrbyNotchDockingMetrics.undockDetachThreshold
    let tension = min(max(pullDistance / threshold, 0), 1)
    let visualDistance = threshold * 0.55 * easeOutCubic(tension)
    let dx = cursor.x - anchor.x
    let dy = cursor.y - anchor.y
    let inv = 1 / pullDistance
    return CGSize(width: dx * inv * visualDistance, height: dy * inv * visualDistance)
  }

  static func pullTension(pullDistance: CGFloat) -> CGFloat {
    let threshold = OrbyNotchDockingMetrics.undockDetachThreshold
    return min(max(pullDistance / threshold, 0), 1)
  }

  // MARK: - Private

  private static func proximityToAnchor(from point: NSPoint, layout: OrbyNotchLayout) -> CGFloat {
    guard layout.captureZone.contains(point) else { return 0 }
    let anchor = layout.notchAnchor
    let maxDistance = hypot(
      layout.captureZone.width * 0.45,
      layout.captureZone.height * 0.55
    )
    let distance = hypot(point.x - anchor.x, point.y - anchor.y)
    let normalized = 1 - min(max(distance / maxDistance, 0), 1)
    return smoothstep(normalized)
  }

  private static func easeOutCubic(_ t: CGFloat) -> CGFloat {
    let x = min(max(t, 0), 1)
    let u = 1 - x
    return 1 - u * u * u
  }

  static func isNotchedBuiltInDisplay(_ screen: NSScreen) -> Bool {
    guard isBuiltInDisplay(screen) else { return false }
    if #available(macOS 12.0, *) {
      return screen.safeAreaInsets.top > 0
    }
    return false
  }

  private static func isBuiltInDisplay(_ screen: NSScreen) -> Bool {
    guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
      return false
    }
    let displayID = CGDirectDisplayID(number.uint32Value)
    return CGDisplayIsBuiltin(displayID) != 0
  }

  static func screen(containing point: NSPoint) -> NSScreen? {
    NSScreen.screens.first { $0.frame.contains(point) }
      ?? NSScreen.screens.first { $0.frame.intersects(CGRect(origin: point, size: .zero)) }
  }

  private static func smoothstep(_ t: CGFloat) -> CGFloat {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
  }
}
