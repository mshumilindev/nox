import Foundation

enum OrbyIdleMicrobehaviorWeights {
  /// Weighted random among context-eligible behaviors (no mood gate).
  static func pickRandom(
    context: OrbyIdleMicroContext,
    excluding excluded: OrbyIdleMicrobehavior? = nil,
    disallow: Set<OrbyIdleMicrobehavior> = []
  ) -> OrbyIdleMicrobehavior? {
    var eligible = OrbyIdleMicrobehavior.allCases.filter {
      OrbyIdleMicrobehaviorPolicy.canRun($0, context: context)
    }
    if !disallow.isEmpty {
      eligible.removeAll { disallow.contains($0) }
    }
    if let excluded, eligible.count > 1 {
      eligible.removeAll { $0 == excluded }
    }
    return weightedRandom(from: eligible)
  }

  private static func weightedRandom(from eligible: [OrbyIdleMicrobehavior]) -> OrbyIdleMicrobehavior? {
    let weighted = eligible.flatMap { behavior in
      Array(repeating: behavior, count: selectionWeight(for: behavior))
    }
    return weighted.randomElement()
  }

  private static func selectionWeight(for behavior: OrbyIdleMicrobehavior) -> Int {
    switch behavior {
    case .eyeWander, .glanceAround:
      return 1
    case .humPulse, .microSmile, .sleepyNod, .pixelShiver:
      return 4
    case .selfPolish, .tinyYawn, .sideEye:
      return 5
    case .tonguePeek, .bubbleBlow, .cheekPuff, .sparkleCatch, .tinySneeze:
      return 10
    case .animeSelfSatisfied, .noirDetective, .cosmicCometWatch, .catMode, .blackHoleNibble:
      // When the stylized cooldown bucket opens (gated by the scheduler) we want a
      // stylized beat to actually win the draw, so it reads as a deliberate moment.
      return 16
    case .saturnRingOrbit:
      return 1
    }
  }
}
