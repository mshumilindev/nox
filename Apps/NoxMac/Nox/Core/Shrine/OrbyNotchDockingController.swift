import AppKit
import Foundation
import Observation

/// Coordinates fake Dynamic Notch docking / undocking between bubble and notch panels.
@MainActor
@Observable
final class OrbyNotchDockingController {
  let notchPanel = ShrineNotchPanelController()

  private(set) var surfaceForm: OrbySurfaceForm = .bubble
  private(set) var dragState: OrbyDockingDragState = .none
  private(set) var isDockPreviewActive = false
  private(set) var isDockedInNotch = false
  private(set) var isPullingFromNotch = false
  private(set) var hasDetachedFromNotchDuringDrag = false

  /// Visual offsets for notch pull resistance (SwiftUI).
  private(set) var notchOrbyVisualOffset: CGSize = .zero
  private(set) var notchOrbyStretchScale: CGSize = CGSize(width: 1, height: 1)
  private(set) var fakeNotchGlowIntensity: CGFloat = 0.35
  private(set) var fakeNotchPullTension: CGFloat = 0
  private(set) var isDraggingTowardNotch = false
  private(set) var dockPreviewProximity: CGFloat = 0
  /// 0 = fully retracted (invisible), 1 = fully extended. Drives the capsule clip.
  private(set) var fakeNotchWidthFraction: CGFloat = 0
  /// Horizontal offset to position Orby within the extended capsule.
  var orbyXOffsetInCapsule: CGFloat {
    activeLayout?.orbyXOffsetFromCapsuleCenter ?? 0
  }
  private var notchAnimTask: Task<Void, Never>?
  private enum NotchWidthAnimationTarget {
    case extended
    case retracted
  }
  private var notchWidthAnimationTarget: NotchWidthAnimationTarget?

  var fakeNotchFrameSize: CGSize {
    (previewLayout ?? activeLayout)?.fakeNotchFrame.size ?? CGSize(
      width: OrbyNotchDockingMetrics.fakeNotchWidth,
      height: OrbyNotchDockingMetrics.fakeNotchHeight
    )
  }

  var fakeNotchVisualState: FakeNotchVisualState {
    if isPullingFromNotch, !hasDetachedFromNotchDuringDrag {
      return .undockResistance(tension: fakeNotchPullTension)
    }
    if isDockPreviewActive {
      return .dockingPreview(proximity: dockPreviewProximity)
    }
    if isDockedInNotch {
      return .docked
    }
    return .hidden
  }

  private weak var bubblePanel: ShrineMiniPanelController?
  private weak var visual: OrbyMiniVisualController?
  private weak var surfaceController: ShrineSurfaceController?

  private var activeLayout: OrbyNotchLayout?
  private var previewLayout: OrbyNotchLayout?
  private var wasUndockedFromNotchDuringCurrentDrag = false
  private var retractAnimationTask: Task<Void, Never>?
  private var undockEventMonitor: Any?
  private var undockDragTracker = OrbyDragGestureTracker()
  private var undockArmed = false

  private let defaults: UserDefaults
  private let dockedStorageKey = "dev.nox.shrine.isDockedInNotch"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    isDockedInNotch = defaults.bool(forKey: dockedStorageKey)
    if isDockedInNotch {
      surfaceForm = .notch
      dragState = .dockedInNotch
    }
  }

  func bind(
    bubblePanel: ShrineMiniPanelController,
    visual: OrbyMiniVisualController,
    surfaceController: ShrineSurfaceController,
    environment: AppEnvironment
  ) {
    self.bubblePanel = bubblePanel
    self.visual = visual
    self.surfaceController = surfaceController
    notchPanel.bind(
      environment: environment,
      surfaceController: surfaceController,
      dockingController: self
    )
    visual.setSurfaceForm(surfaceForm)
    visual.onPostDragDazedFinished = { [weak self] in
      self?.completePendingUndockRetractIfReady()
    }
  }

  // MARK: - Show / hide

  func showPreferredSurface(playLaunchGreeting: Bool) {
    if isDockedInNotch, let layout = resolveDockedLayout() {
      activeLayout = layout
      bubblePanel?.hide()
      notchPanel.showDocked(layout: layout, animated: false)
      visual?.noteShow(playLaunchGreeting: false)
      visual?.setSurfaceForm(.notch)
      surfaceForm = .notch
      dragState = .dockedInNotch
      fakeNotchGlowIntensity = 0
      notchWidthAnimationTarget = nil
      fakeNotchWidthFraction = 1
      return
    }
    bubblePanel?.showAtDefaultPosition()
    visual?.noteShow(playLaunchGreeting: playLaunchGreeting)
    visual?.setSurfaceForm(.bubble)
    surfaceForm = .bubble
    dragState = .none
    notchPanel.hide()
  }

  func hideAll() {
    retractAnimationTask?.cancel()
    notchAnimTask?.cancel()
    notchWidthAnimationTarget = nil
    pendingRetractLayout = nil
    detachedJumpHasReachedCursor = false
    isWaitingForDazedBeforeRetract = false
    removeUndockEventMonitor()
    bubblePanel?.hide()
    notchPanel.hide()
    clearPreviewState()
    visual?.setSurfaceForm(.bubble)
  }

  func notchAnchorY(for screen: NSScreen) -> CGFloat? {
    if let previewLayout, previewLayout.screenFrame == screen.frame {
      return previewLayout.notchAnchor.y
    }
    if let activeLayout, activeLayout.screenFrame == screen.frame {
      return activeLayout.notchAnchor.y
    }
    return OrbyNotchGeometry.layout(for: screen)?.notchAnchor.y
  }

  func noteContextMenuOpened() {
    visual?.noteContextMenuOpened()
  }

  // MARK: - Bubble drag → dock

  func noteBubbleDrag(orbCenter: NSPoint, mouse: NSPoint) {
    guard !isDockedInNotch, !hasDetachedFromNotchDuringDrag else { return }
    guard let screen = OrbyNotchGeometry.screen(containing: mouse),
          let layout = OrbyNotchGeometry.layout(for: screen) else {
      isDraggingTowardNotch = false
      clearPreviewState()
      bubblePanel?.snapToVisibleFrameIfNeeded(animated: false)
      return
    }

    isDraggingTowardNotch = OrbyNotchGeometry.isCursorInNotchCaptureCorridor(cursor: mouse, on: screen)
    previewLayout = layout

    let inCorridor = isDraggingTowardNotch
      || OrbyNotchGeometry.isInCaptureZone(cursor: mouse, layout: layout)
      || OrbyNotchGeometry.isInCaptureZone(orbCenter: orbCenter, layout: layout)

    if inCorridor {
      let proximity = OrbyNotchGeometry.proximity(from: orbCenter, cursor: mouse, layout: layout)
      dockPreviewProximity = proximity
      isDockPreviewActive = true
      dragState = proximity > 0.55 ? .dockingPreview(proximity: proximity) : .bubbleDraggingNearNotch(proximity: proximity)
      fakeNotchGlowIntensity = 0.35 + proximity * 0.55

      // Size blend only when Orby's body actually overlaps the Orby dock area.
      let orbRadius = OrbyOrbGeometry.orbDiameter / 2
      let orbyAreaW = OrbyNotchDockingMetrics.fakeNotchWidth
      let orbyAreaRect = CGRect(
        x: layout.notchAnchor.x - orbyAreaW / 2,
        y: layout.fakeNotchFrame.minY,
        width: orbyAreaW,
        height: layout.fakeNotchFrame.height
      )
      let hitZone = orbyAreaRect.insetBy(dx: -orbRadius, dy: -orbRadius)
      if hitZone.contains(orbCenter) {
        let dist = hypot(orbCenter.x - layout.notchAnchor.x, orbCenter.y - layout.notchAnchor.y)
        let maxDist = hypot(hitZone.width / 2, hitZone.height / 2)
        let sizeBlend = min(max(1 - dist / maxDist, 0), 1)
        visual?.setNotchPreviewBlend(sizeBlend)
      } else {
        visual?.setNotchPreviewBlend(0)
      }
      if !notchPanel.isVisible || fakeNotchWidthFraction < 0.01 {
        notchPanel.showPreview(layout: layout, animated: true)
      }
      animateNotchExtend()
    } else {
      clearPreviewState()
      bubblePanel?.snapToVisibleFrameIfNeeded(animated: false)
    }
  }

  func endBubbleDrag(orbCenter: NSPoint, cursor: NSPoint, metrics: OrbyDragGestureMetrics) {
    defer {
      isDraggingTowardNotch = false
      clearPreviewState()
    }

    if let layout = previewLayout ?? OrbyNotchGeometry.layout(forScreenContaining: cursor),
       OrbyNotchGeometry.isInDropZone(point: cursor, layout: layout) {
      dock(into: layout)
      visual?.endDrag(metrics: metrics, forcedUndock: false, forceNormal: true)
      return
    }

    visual?.endDrag(metrics: metrics, forcedUndock: false)
    bubblePanel?.snapToVisibleFrameIfNeeded(animated: true)
  }

  func noteBubbleDragBegan() {
    hasDetachedFromNotchDuringDrag = false
    wasUndockedFromNotchDuringCurrentDrag = false
    isDraggingTowardNotch = false
    notchPanel.resetPreviewState()
  }

  // MARK: - Notch undock drag

  func beginNotchUndockDrag(at mouse: NSPoint) {
    guard isDockedInNotch, let layout = activeLayout ?? resolveDockedLayout() else { return }
    activeLayout = layout
    undockArmed = true
    isPullingFromNotch = false
    hasDetachedFromNotchDuringDrag = false
    wasUndockedFromNotchDuringCurrentDrag = false
    undockDragTracker.begin(at: mouse)
    installUndockEventMonitor()
    notchPanel.showPulling(layout: layout, animated: true)
  }

  func noteNotchUndockDragStep(at mouse: NSPoint, screenDelta: CGSize, sampleTime: Date) {
    guard let layout = activeLayout else { return }
    undockDragTracker.addSample(at: mouse, time: sampleTime)

    let anchor = layout.notchAnchor
    let pullDistance = hypot(mouse.x - anchor.x, mouse.y - anchor.y)

    if undockArmed, pullDistance > 3 {
      undockArmed = false
      isPullingFromNotch = true
      visual?.beginDrag()
      visual?.setSurfaceForm(.notch)
    }
    guard isPullingFromNotch, !hasDetachedFromNotchDuringDrag else { return }

    _ = screenDelta
    let tension = OrbyNotchGeometry.pullTension(pullDistance: pullDistance)
    fakeNotchPullTension = tension
    fakeNotchGlowIntensity = 0

    if pullDistance >= OrbyNotchDockingMetrics.undockDetachThreshold {
      detachFromNotch(to: mouse, layout: layout)
      return
    }

    dragState = .notchPullingOut(distance: pullDistance, tension: tension)
    // Orby stays in place at anchor — no visual offset. Angry face + tremble convey resistance.
    notchOrbyVisualOffset = .zero
    notchOrbyStretchScale = CGSize(width: 1, height: 1)
    visual?.setNotchPullVisual(offset: .zero, tension: tension)
    visual?.noteDragStep(screenDelta: screenDelta, sampleTime: sampleTime)
  }

  func endNotchUndockDrag(metrics: OrbyDragGestureMetrics) {
    removeUndockEventMonitor()
    undockArmed = false

    if hasDetachedFromNotchDuringDrag {
      isPullingFromNotch = false
      if !detachedJumpHasReachedCursor {
        moveBubble(to: NSEvent.mouseLocation)
        detachedJumpHasReachedCursor = true
      }
      completePendingUndockRetractIfReady()
      visual?.endDrag(metrics: metrics, forcedUndock: false, forceNormal: true)
      resetPullVisuals()
      resetUndockSessionFlags()
      bubblePanel?.snapToVisibleFrameIfNeeded(animated: true)
      return
    }

    guard isPullingFromNotch else {
      if let layout = activeLayout {
        notchPanel.showDocked(layout: layout, animated: true)
      }
      return
    }

    isPullingFromNotch = false
    dragState = .dockedInNotch
    visual?.endDrag(metrics: metrics, forcedUndock: false)
    visual?.clearNotchPullVisual()
    animateRetractToNotch()
  }

  // MARK: - Private

  private func dock(into layout: OrbyNotchLayout) {
    isDockedInNotch = true
    isDockPreviewActive = false
    pendingRetractLayout = nil
    detachedJumpHasReachedCursor = false
    isWaitingForDazedBeforeRetract = false
    surfaceForm = .notch
    activeLayout = layout
    dragState = .dockedInNotch
    persistDocked(true)
    bubblePanel?.hide()
    notchAnimTask?.cancel()
    notchWidthAnimationTarget = nil
    fakeNotchWidthFraction = 1
    notchPanel.showDocked(layout: layout, animated: true)
    visual?.setSurfaceForm(.notch)
    visual?.clearNotchPreviewBlend()
    fakeNotchGlowIntensity = 0
    fakeNotchPullTension = 0
    dockPreviewProximity = 0
    notchOrbyVisualOffset = .zero
    notchOrbyStretchScale = CGSize(width: 1, height: 1)
  }

  private func detachFromNotch(to mouse: NSPoint, layout: OrbyNotchLayout) {
    guard !hasDetachedFromNotchDuringDrag else { return }
    hasDetachedFromNotchDuringDrag = true
    wasUndockedFromNotchDuringCurrentDrag = true
    isDockedInNotch = false
    isPullingFromNotch = false
    isDockPreviewActive = false
    surfaceForm = .bubble
    dragState = .undockedDuringDrag
    persistDocked(false)

    // Don't hide the shell until Bubble Orby has jumped to the cursor.
    pendingRetractLayout = layout
    detachedJumpHasReachedCursor = false
    isWaitingForDazedBeforeRetract = false
    resetPullVisuals()
    visual?.clearNotchPullVisual()
    visual?.setSurfaceForm(.bubble)
    visual?.clearNotchPreviewBlend()
    notchPanel.showRetractShell(layout: layout)

    guard let bubblePanel else { return }
    bubblePanel.showWithoutDefaultPlacement()
    // Start at the notch anchor; drag handler lerps smoothly toward cursor.
    moveBubble(to: layout.notchAnchor)
    detachLerpProgress = 0
    visual?.beginDrag()
    undockDragTracker.addSample(at: mouse)
  }

  private func installUndockEventMonitor() {
    removeUndockEventMonitor()
    undockEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
      guard let self else { return event }
      let mouse = NSEvent.mouseLocation
      switch event.type {
      case .leftMouseDragged:
        let time = Date(timeIntervalSinceReferenceDate: event.timestamp)
        if self.hasDetachedFromNotchDuringDrag {
          self.handleDetachedBubbleDrag(at: mouse, time: time)
        } else {
          self.noteNotchUndockDragStep(at: mouse, screenDelta: .zero, sampleTime: time)
        }
      case .leftMouseUp:
        let time = Date(timeIntervalSinceReferenceDate: event.timestamp)
        let metrics = self.undockDragTracker.finish(at: mouse, time: time)
        let shouldConsume = self.isPullingFromNotch || self.hasDetachedFromNotchDuringDrag
        self.endNotchUndockDrag(metrics: metrics)
        return shouldConsume ? nil : event
      default:
        break
      }
      return event
    }
  }

  private func removeUndockEventMonitor() {
    if let undockEventMonitor {
      NSEvent.removeMonitor(undockEventMonitor)
      self.undockEventMonitor = nil
    }
  }

  /// 0…1 lerp ramp after detach; reaches 1 after ~8 drag events then snaps directly.
  private var detachLerpProgress: CGFloat = 1
  /// Layout to retract the notch panel after the lerp completes.
  private var pendingRetractLayout: OrbyNotchLayout?
  private var detachedJumpHasReachedCursor = false
  private var isWaitingForDazedBeforeRetract = false

  private func handleDetachedBubbleDrag(at mouse: NSPoint, time: Date) {
    undockDragTracker.addSample(at: mouse, time: time)

    // Check if user dragged back into the dock zone — allow re-docking.
    if let layout = activeLayout,
       OrbyNotchGeometry.isInDropZone(point: mouse, layout: layout) {
      bubblePanel?.hide()
      hasDetachedFromNotchDuringDrag = false
      wasUndockedFromNotchDuringCurrentDrag = false
      let metrics = undockDragTracker.finish(at: mouse, time: time)
      visual?.endDrag(metrics: metrics, forcedUndock: false, forceNormal: true)
      removeUndockEventMonitor()
      dock(into: layout)
      return
    }

    if detachLerpProgress < 1 {
      detachLerpProgress = min(detachLerpProgress + 0.15, 1)
      let eased = detachLerpProgress * detachLerpProgress * (3 - 2 * detachLerpProgress)
      guard let bubblePanel else { return }
      let current = bubblePanel.currentOrigin ?? NSPoint(x: mouse.x, y: mouse.y)
      let panelSize = bubblePanel.panelSize
      let currentCenter = NSPoint(
        x: current.x + panelSize.width / 2,
        y: current.y + panelSize.height / 2
      )
      let interpolated = NSPoint(
        x: currentCenter.x + (mouse.x - currentCenter.x) * eased,
        y: currentCenter.y + (mouse.y - currentCenter.y) * eased
      )
      moveBubble(to: interpolated)

      // Once lerp completes, Orby has reached the cursor; hide the empty shell immediately.
      if detachLerpProgress >= 1, pendingRetractLayout != nil {
        detachedJumpHasReachedCursor = true
        completePendingUndockRetractIfReady()
      }
    } else {
      moveBubble(to: mouse)
      detachedJumpHasReachedCursor = true
    }
    visual?.noteDragStep(screenDelta: .zero, sampleTime: time)
  }

  private func completePendingUndockRetractIfReady() {
    guard detachedJumpHasReachedCursor,
          pendingRetractLayout != nil else { return }
    pendingRetractLayout = nil
    isWaitingForDazedBeforeRetract = false
    notchAnimTask?.cancel()
    notchWidthAnimationTarget = nil
    fakeNotchWidthFraction = 0
    notchPanel.hide()
  }

  private func moveBubble(to mouse: NSPoint) {
    guard let bubblePanel else { return }
    let panelSize = bubblePanel.panelSize
    let origin = NSPoint(
      x: mouse.x - panelSize.width / 2,
      y: mouse.y - panelSize.height / 2
    )
    bubblePanel.setFrameOrigin(origin, persist: false, cursor: mouse)
  }

  private func animateRetractToNotch() {
    retractAnimationTask?.cancel()
    retractAnimationTask = Task { @MainActor in
      let steps = 10
      let startTension = fakeNotchPullTension
      let startOffset = notchOrbyVisualOffset
      for step in 1...steps {
        guard !Task.isCancelled else { return }
        let t = CGFloat(step) / CGFloat(steps)
        let eased = t * t * (3 - 2 * t)
        fakeNotchPullTension = startTension * (1 - eased)
        let offset = CGSize(
          width: startOffset.width * (1 - eased),
          height: startOffset.height * (1 - eased)
        )
        notchOrbyVisualOffset = offset
        visual?.setNotchPullVisual(offset: offset, tension: fakeNotchPullTension)
        try? await Task.sleep(nanoseconds: UInt64(OrbyNotchDockingMetrics.undockRetractSeconds / Double(steps) * 1_000_000_000))
      }
      notchOrbyVisualOffset = .zero
      notchOrbyStretchScale = CGSize(width: 1, height: 1)
      fakeNotchPullTension = 0
      fakeNotchGlowIntensity = 0
      visual?.clearNotchPullVisual()
      if let layout = activeLayout {
        notchPanel.showDocked(layout: layout, animated: true)
      }
    }
  }

  private func clearPreviewState() {
    isDockPreviewActive = false
    dockPreviewProximity = 0
    previewLayout = nil
    if !isDockedInNotch, !hasDetachedFromNotchDuringDrag {
      dragState = .none
      animateNotchRetract()
    }
    visual?.clearNotchPreviewBlend()
    if !isPullingFromNotch {
      fakeNotchGlowIntensity = 0
      if !isDockedInNotch {
        fakeNotchPullTension = 0
      }
    }
  }

  private func resetPullVisuals() {
    notchOrbyVisualOffset = .zero
    notchOrbyStretchScale = CGSize(width: 1, height: 1)
    fakeNotchPullTension = 0
  }

  private func resetUndockSessionFlags() {
    hasDetachedFromNotchDuringDrag = false
    wasUndockedFromNotchDuringCurrentDrag = false
    dragState = .none
  }

  // MARK: - Notch width animation

  /// Animate fakeNotchWidthFraction from current value to 1 (extend).
  private func animateNotchExtend() {
    guard notchWidthAnimationTarget != .extended else { return }
    notchWidthAnimationTarget = .extended
    notchAnimTask?.cancel()
    notchAnimTask = Task { @MainActor in
      let start = fakeNotchWidthFraction
      let steps = 12
      for i in 1...steps {
        guard !Task.isCancelled else { return }
        let t = CGFloat(i) / CGFloat(steps)
        let eased = t * t * (3 - 2 * t)
        fakeNotchWidthFraction = start + (1 - start) * eased
        try? await Task.sleep(nanoseconds: 18_000_000)
      }
      fakeNotchWidthFraction = 1
      notchWidthAnimationTarget = nil
    }
  }

  /// Animate fakeNotchWidthFraction from current value to 0 (retract), then hide panel.
  private func animateNotchRetract() {
    guard notchWidthAnimationTarget != .retracted else { return }
    notchWidthAnimationTarget = .retracted
    notchAnimTask?.cancel()
    notchAnimTask = Task { @MainActor in
      let start = fakeNotchWidthFraction
      let steps = 10
      for i in 1...steps {
        guard !Task.isCancelled else { return }
        let t = CGFloat(i) / CGFloat(steps)
        let eased = t * t * (3 - 2 * t)
        fakeNotchWidthFraction = start * (1 - eased)
        try? await Task.sleep(nanoseconds: 18_000_000)
      }
      fakeNotchWidthFraction = 0
      notchWidthAnimationTarget = nil
      notchPanel.hide()
    }
  }

  private func persistDocked(_ docked: Bool) {
    defaults.set(docked, forKey: dockedStorageKey)
  }

  private func resolveDockedLayout() -> OrbyNotchLayout? {
    if let activeLayout { return activeLayout }
    if let main = NSScreen.main, let layout = OrbyNotchGeometry.layout(for: main) {
      activeLayout = layout
      return layout
    }
    for screen in NSScreen.screens {
      if let layout = OrbyNotchGeometry.layout(for: screen) {
        activeLayout = layout
        return layout
      }
    }
    isDockedInNotch = false
    persistDocked(false)
    surfaceForm = .bubble
    return nil
  }
}
