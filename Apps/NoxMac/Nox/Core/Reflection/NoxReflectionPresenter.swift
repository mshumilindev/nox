import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

nonisolated enum NoxReflectionPresenter {
    static let defaultDetailLine = "Grounded in recent local memory — not advice."

    static func distinct(_ reflections: [NoxReflectionCandidate], limit: Int = 4) -> [NoxReflectionCandidate] {
        var seenText = Set<String>()
        var seenId = Set<String>()
        var results: [NoxReflectionCandidate] = []
        for reflection in reflections.sorted(by: { $0.createdAt > $1.createdAt }) {
            let normalized = reflection.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard seenText.insert(normalized).inserted else { continue }
            guard seenId.insert(reflection.id).inserted else { continue }
            results.append(reflection)
            if results.count >= limit { break }
        }
        return results
    }
}
