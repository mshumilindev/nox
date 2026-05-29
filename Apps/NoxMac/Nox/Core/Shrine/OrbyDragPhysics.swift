import CoreGraphics
import Foundation

// MARK: - Presentation

/// Visual-only drag deformation snapshot (never persisted).
struct OrbyDragDeformationSnapshot: Equatable {
  var stretch: CGFloat = 1
  var compression: CGFloat = 1
  var angleRadians: CGFloat = 0
  var faceLagOffset: CGSize = .zero
}

// MARK: - Constants

struct OrbyDragPhysicsConstants: Equatable {
  var velocitySmoothing: CGFloat = 0.35
  var accelerationSmoothing: CGFloat = 0.20
  var velocityDeadZone: CGFloat = 40
  var deformationSoftStartSpeed: CGFloat = 180
  var deformationMaxVisualSpeed: CGFloat = 1250
  var stretchMaxDelta: CGFloat = 0.09
  var compressionMaxDelta: CGFloat = 0.065
  var absoluteStretchCap: CGFloat = 1.14
  var absoluteCompressionFloor: CGFloat = 0.88
  var accelBoostSoftStart: CGFloat = 2400
  var accelBoostMax: CGFloat = 10_000
  var accelStretchBoost: CGFloat = 0.03
  var accelCompressionBoost: CGFloat = 0.025
  var maxFaceLag: CGFloat = 8.5
  var faceLagStiffness: CGFloat = 70
  var faceLagDamping: CGFloat = 12
  var deformationStiffness: CGFloat = 240
  var deformationDamping: CGFloat = 22
  var normalReleaseStiffness: CGFloat = 185
  var normalReleaseDamping: CGFloat = 18
  var dazedReleaseStiffness: CGFloat = 128
  var dazedReleaseDamping: CGFloat = 13
  var faceInheritDeformationStrength: CGFloat = 0.36
  var settleEpsilon: CGFloat = 0.004
  var maxFrameDt: TimeInterval = 1.0 / 30.0
}

// MARK: - Math (testable)

enum OrbyDragPhysicsMath {
  static func easeOutCubic(_ x: CGFloat) -> CGFloat {
    let t = min(max(x, 0), 1)
    return 1 - pow(1 - t, 3)
  }

  static func dragIntensity(
    smoothedSpeed: CGFloat,
    softStart: CGFloat,
    maxVisual: CGFloat
  ) -> CGFloat {
    guard maxVisual > softStart else { return 0 }
    let raw = (smoothedSpeed - softStart) / (maxVisual - softStart)
    return min(max(raw, 0), 1)
  }

  static func deformationTargets(
    deformationIntensity: CGFloat,
    accelerationMagnitude: CGFloat,
    constants: OrbyDragPhysicsConstants
  ) -> (stretch: CGFloat, compression: CGFloat) {
    var stretch = 1 + constants.stretchMaxDelta * deformationIntensity
    var compression = 1 - constants.compressionMaxDelta * deformationIntensity

    let accelSpan = constants.accelBoostMax - constants.accelBoostSoftStart
    if accelSpan > 0 {
      let accelBoost = min(
        max((accelerationMagnitude - constants.accelBoostSoftStart) / accelSpan, 0),
        1
      )
      stretch += constants.accelStretchBoost * accelBoost
      compression -= constants.accelCompressionBoost * accelBoost
    }

    stretch = min(stretch, constants.absoluteStretchCap)
    compression = max(compression, constants.absoluteCompressionFloor)
    return (stretch, compression)
  }

  static func faceLagTarget(
    dragDirection: CGVector,
    deformationIntensity: CGFloat,
    maxLag: CGFloat
  ) -> CGSize {
    let length = vectorLength(dragDirection)
    guard length > 0.0001 else { return .zero }
    let nx = dragDirection.dx / length
    let ny = dragDirection.dy / length
    let mag = maxLag * deformationIntensity
    return CGSize(width: -nx * mag, height: -ny * mag)
  }

  static func directionAngle(for velocity: CGVector, deadZone: CGFloat) -> CGFloat? {
    let speed = vectorLength(velocity)
    guard speed >= deadZone else { return nil }
    return atan2(velocity.dy, velocity.dx)
  }

  static func lerpVector(_ current: CGVector, _ target: CGVector, factor: CGFloat) -> CGVector {
    CGVector(
      dx: current.dx + (target.dx - current.dx) * factor,
      dy: current.dy + (target.dy - current.dy) * factor
    )
  }

  static func vectorLength(_ v: CGVector) -> CGFloat {
    hypot(v.dx, v.dy)
  }

  static func screenDeltaToViewVelocity(delta: CGSize, dt: TimeInterval) -> CGVector {
    let invDt = CGFloat(1 / max(dt, 1.0 / 120.0))
    // macOS screen space: +y up. SwiftUI local: +y down.
    return CGVector(dx: delta.width * invDt, dy: -delta.height * invDt)
  }

  static func integrateSpring(
    value: inout CGFloat,
    velocity: inout CGFloat,
    target: CGFloat,
    stiffness: CGFloat,
    damping: CGFloat,
    dt: CGFloat
  ) {
    let force = (target - value) * stiffness - velocity * damping
    velocity += force * dt
    value += velocity * dt
  }

  static func integrateSpring2D(
    position: inout CGSize,
    velocity: inout CGSize,
    target: CGSize,
    stiffness: CGFloat,
    damping: CGFloat,
    dt: CGFloat
  ) {
    let fx = (target.width - position.width) * stiffness - velocity.width * damping
    let fy = (target.height - position.height) * stiffness - velocity.height * damping
    velocity.width += fx * dt
    velocity.height += fy * dt
    position.width += velocity.width * dt
    position.height += velocity.height * dt
  }
}

// MARK: - Simulator

/// In-memory visual drag physics (panel position is unaffected).
@MainActor
final class OrbyDragPhysicsSimulator {
  private var constants = OrbyDragPhysicsConstants()
  private var mode: Mode = .idle

  private var smoothedVelocity = CGVector.zero
  private var smoothedAcceleration = CGVector.zero
  private var previousInstantVelocity = CGVector.zero
  private var lastDirectionAngle: CGFloat = 0
  private var lastSampleTime: Date?

  private var stretch: CGFloat = 1
  private var compression: CGFloat = 1
  private var stretchVelocity: CGFloat = 0
  private var compressionVelocity: CGFloat = 0
  private var angleRadians: CGFloat = 0

  private var faceLagOffset = CGSize.zero
  private var faceLagVelocity = CGSize.zero

  private enum Mode: Equatable {
    case idle
    case dragging
    case releasing(dazed: Bool)
  }

  var isActive: Bool {
    switch mode {
    case .idle:
      return false
    case .dragging, .releasing:
      return true
    }
  }

  var needsFrameUpdates: Bool {
    switch mode {
    case .idle:
      return false
    case .dragging:
      return true
    case .releasing:
      return !isSettled
    }
  }

  private var isSettled: Bool {
    abs(stretch - 1) < constants.settleEpsilon
      && abs(compression - 1) < constants.settleEpsilon
      && hypot(faceLagOffset.width, faceLagOffset.height) < constants.settleEpsilon
      && abs(stretchVelocity) < constants.settleEpsilon
      && abs(compressionVelocity) < constants.settleEpsilon
  }

  func snapshot() -> OrbyDragDeformationSnapshot {
    OrbyDragDeformationSnapshot(
      stretch: stretch,
      compression: compression,
      angleRadians: angleRadians,
      faceLagOffset: faceLagOffset
    )
  }

  func begin(sampleTime: Date = Date()) {
    resetState()
    mode = .dragging
    lastSampleTime = sampleTime
  }

  func ingest(screenDelta: CGSize, sampleTime: Date) {
    guard mode == .dragging else { return }

    let dt: TimeInterval
    if let last = lastSampleTime {
      dt = min(max(sampleTime.timeIntervalSince(last), 1.0 / 120.0), constants.maxFrameDt)
    } else {
      dt = 1.0 / 60.0
    }
    lastSampleTime = sampleTime

    let instant = OrbyDragPhysicsMath.screenDeltaToViewVelocity(delta: screenDelta, dt: dt)
    let c = constants

    smoothedVelocity = OrbyDragPhysicsMath.lerpVector(
      smoothedVelocity, instant, factor: c.velocitySmoothing
    )

    let instantAccel = CGVector(
      dx: (instant.dx - previousInstantVelocity.dx) / CGFloat(dt),
      dy: (instant.dy - previousInstantVelocity.dy) / CGFloat(dt)
    )
    previousInstantVelocity = instant
    smoothedAcceleration = OrbyDragPhysicsMath.lerpVector(
      smoothedAcceleration, instantAccel, factor: c.accelerationSmoothing
    )

    if let angle = OrbyDragPhysicsMath.directionAngle(
      for: smoothedVelocity,
      deadZone: c.velocityDeadZone
    ) {
      lastDirectionAngle = angle
      angleRadians = angle
    }

    let speed = OrbyDragPhysicsMath.vectorLength(smoothedVelocity)
    let rawIntensity = OrbyDragPhysicsMath.dragIntensity(
      smoothedSpeed: speed,
      softStart: c.deformationSoftStartSpeed,
      maxVisual: c.deformationMaxVisualSpeed
    )
    let deformationIntensity = OrbyDragPhysicsMath.easeOutCubic(rawIntensity)
    let accelMag = OrbyDragPhysicsMath.vectorLength(smoothedAcceleration)
    let targets = OrbyDragPhysicsMath.deformationTargets(
      deformationIntensity: deformationIntensity,
      accelerationMagnitude: accelMag,
      constants: c
    )

    let direction = speed >= c.velocityDeadZone
      ? smoothedVelocity
      : CGVector(dx: cos(lastDirectionAngle), dy: sin(lastDirectionAngle))
    let faceTarget = OrbyDragPhysicsMath.faceLagTarget(
      dragDirection: direction,
      deformationIntensity: deformationIntensity,
      maxLag: c.maxFaceLag
    )

    stepSprings(
      stretchTarget: targets.stretch,
      compressionTarget: targets.compression,
      faceTarget: faceTarget,
      stiffness: c.deformationStiffness,
      damping: c.deformationDamping,
      faceStiffness: c.faceLagStiffness,
      faceDamping: c.faceLagDamping,
      dt: CGFloat(dt)
    )
  }

  func advanceFrame(dt: TimeInterval) {
    let clamped = min(max(dt, 1.0 / 120.0), constants.maxFrameDt)
    let dtCG = CGFloat(clamped)

    switch mode {
    case .idle:
      break
    case .dragging:
      // Decay toward rest when pointer pauses mid-drag.
      let speed = OrbyDragPhysicsMath.vectorLength(smoothedVelocity)
      if speed < constants.velocityDeadZone {
        smoothedVelocity = OrbyDragPhysicsMath.lerpVector(smoothedVelocity, .zero, factor: 0.2)
        let targets = OrbyDragPhysicsMath.deformationTargets(
          deformationIntensity: 0,
          accelerationMagnitude: 0,
          constants: constants
        )
        stepSprings(
          stretchTarget: targets.stretch,
          compressionTarget: targets.compression,
          faceTarget: .zero,
          stiffness: constants.deformationStiffness,
          damping: constants.deformationDamping,
          faceStiffness: constants.faceLagStiffness,
          faceDamping: constants.faceLagDamping,
          dt: dtCG
        )
      }
    case .releasing(let dazed):
      let stiffness = dazed ? constants.dazedReleaseStiffness : constants.normalReleaseStiffness
      let damping = dazed ? constants.dazedReleaseDamping : constants.normalReleaseDamping
      stepSprings(
        stretchTarget: 1,
        compressionTarget: 1,
        faceTarget: .zero,
        stiffness: stiffness,
        damping: damping,
        faceStiffness: constants.faceLagStiffness * (dazed ? 0.85 : 1),
        faceDamping: constants.faceLagDamping,
        dt: dtCG
      )
      smoothedVelocity = OrbyDragPhysicsMath.lerpVector(smoothedVelocity, .zero, factor: 0.35)
      if isSettled {
        resetState()
      }
    }
  }

  func release(dazed: Bool) {
    mode = .releasing(dazed: dazed)
    lastSampleTime = nil
    smoothedVelocity = .zero
    smoothedAcceleration = .zero
    previousInstantVelocity = .zero
  }

  func reset() {
    resetState()
  }

  var faceDeformationStrength: CGFloat {
    switch mode {
    case .idle:
      0
    case .dragging, .releasing:
      constants.faceInheritDeformationStrength
    }
  }

  private func stepSprings(
    stretchTarget: CGFloat,
    compressionTarget: CGFloat,
    faceTarget: CGSize,
    stiffness: CGFloat,
    damping: CGFloat,
    faceStiffness: CGFloat,
    faceDamping: CGFloat,
    dt: CGFloat
  ) {
    OrbyDragPhysicsMath.integrateSpring(
      value: &stretch,
      velocity: &stretchVelocity,
      target: stretchTarget,
      stiffness: stiffness,
      damping: damping,
      dt: dt
    )
    OrbyDragPhysicsMath.integrateSpring(
      value: &compression,
      velocity: &compressionVelocity,
      target: compressionTarget,
      stiffness: stiffness,
      damping: damping,
      dt: dt
    )
    stretch = min(stretch, constants.absoluteStretchCap)
    compression = max(compression, constants.absoluteCompressionFloor)

    OrbyDragPhysicsMath.integrateSpring2D(
      position: &faceLagOffset,
      velocity: &faceLagVelocity,
      target: faceTarget,
      stiffness: faceStiffness,
      damping: faceDamping,
      dt: dt
    )
    let maxLag = constants.maxFaceLag
    faceLagOffset = CGSize(
      width: min(max(faceLagOffset.width, -maxLag), maxLag),
      height: min(max(faceLagOffset.height, -maxLag), maxLag)
    )
  }

  private func resetState() {
    mode = .idle
    smoothedVelocity = .zero
    smoothedAcceleration = .zero
    previousInstantVelocity = .zero
    lastSampleTime = nil
    stretch = 1
    compression = 1
    stretchVelocity = 0
    compressionVelocity = 0
    faceLagOffset = .zero
    faceLagVelocity = .zero
  }
}
