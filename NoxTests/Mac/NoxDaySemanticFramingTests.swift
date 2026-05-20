import Foundation
import Testing
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
@testable import Nox

struct NoxDaySemanticFramingTests {

    @Test func overviewMentionsFragmentedDay() {
        let blocks: [NoxTimelineBlockItem] = [
            NoxTimelineBlockItem(
                id: "1",
                timestamp: Date(),
                kind: .semanticSpan(
                    NoxSemanticMemorySpan(
                        id: "1",
                        startedAt: Date(),
                        endedAt: Date(),
                        title: "Fragmented attention period",
                        subtitle: "Many apps",
                        interactionStyle: "",
                        semanticState: .fragmentedInteraction,
                        fusionLabel: .unknown,
                        sensitivityLevel: .normal,
                        confidence: 0.6,
                        appNames: [],
                        reasonsJson: nil
                    )
                ),
                title: "Fragmented attention period",
                subtitle: nil,
                detailLine: nil,
                durationText: "22m",
                category: nil,
                markerSymbol: nil
            )
        ]
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 3_600_000,
            focusedMs: 600_000,
            fragmentedMs: 2_000_000,
            appSwitchCount: 15,
            longestFocusBlockMs: 0,
            dominantApp: nil,
            dominantCategory: nil
        )
        let overview = NoxDaySemanticFraming.overview(blocks: blocks, stats: stats)
        #expect(overview?.localizedCaseInsensitiveContains("contexts") == true)
    }

    @Test func overviewNeedsSecondFragmentedBlock() {
        let blocks = (0..<2).map { i in
            NoxTimelineBlockItem(
                id: "\(i)",
                timestamp: Date(),
                kind: .semanticSpan(
                    NoxSemanticMemorySpan(
                        id: "\(i)",
                        startedAt: Date(),
                        endedAt: Date(),
                        title: "Fragmented attention period",
                        subtitle: "Many apps",
                        interactionStyle: "",
                        semanticState: .fragmentedInteraction,
                        fusionLabel: .unknown,
                        sensitivityLevel: .normal,
                        confidence: 0.6,
                        appNames: [],
                        reasonsJson: nil
                    )
                ),
                title: "Fragmented attention period",
                subtitle: "Many apps",
                detailLine: nil,
                durationText: "10m",
                category: nil,
                markerSymbol: nil
            )
        }
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 3_600_000,
            focusedMs: 600_000,
            fragmentedMs: 2_000_000,
            appSwitchCount: 15,
            longestFocusBlockMs: 0,
            dominantApp: nil,
            dominantCategory: nil
        )
        let overview = NoxDaySemanticFraming.overview(blocks: blocks, stats: stats)
        #expect(overview?.localizedCaseInsensitiveContains("contexts") == true)
    }
}
