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

struct NoxTimelineBlockPresenterTests {

    @Test func activitySpanHiddenWhenCoveredBySemanticSpan() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let semantic = NoxSemanticMemorySpan(
            id: "sem-1",
            startedAt: base,
            endedAt: base.addingTimeInterval(3600),
            title: "Development",
            subtitle: "Cursor",
            interactionStyle: "",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["Cursor"],
            reasonsJson: nil
        )
        let activity = NoxActivitySpan(
            id: "act-1",
            startedAt: base.addingTimeInterval(300),
            endedAt: base.addingTimeInterval(900),
            appName: "Cursor",
            bundleId: "com.cursor",
            windowTitle: nil,
            contextLabel: nil,
            category: .development,
            interruptions: 0,
            focusScore: 0.5,
            metadataJson: nil
        )
        let filtered = NoxTimelineActivityDeduper.filter(
            activitySpans: [activity],
            semanticSpans: [semantic],
            at: base.addingTimeInterval(3600)
        )
        #expect(filtered.isEmpty)
    }

    @Test func activityDedupUsesTimeOverlapNotText() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let semantic = NoxSemanticMemorySpan(
            id: "sem-1",
            startedAt: base,
            endedAt: base.addingTimeInterval(600),
            title: "Development",
            subtitle: "Apps",
            interactionStyle: "",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["Xcode"],
            reasonsJson: nil
        )
        let activity = NoxActivitySpan(
            id: "act-1",
            startedAt: base.addingTimeInterval(120),
            endedAt: base.addingTimeInterval(180),
            appName: "Xcode",
            bundleId: "com.apple.dt.Xcode",
            windowTitle: nil,
            contextLabel: nil,
            category: .development,
            interruptions: 0,
            focusScore: 0.5,
            metadataJson: nil
        )
        let intervalA = NoxTimeInterval(start: activity.startedAt, end: activity.endedAt!)
        let intervalB = NoxTimeInterval(start: semantic.startedAt, end: semantic.endedAt!)
        #expect(intervalA.overlaps(intervalB))
        #expect(NoxTimelineActivityDeduper.filter(activitySpans: [activity], semanticSpans: [semantic], at: base.addingTimeInterval(600)).isEmpty)
    }

    @Test func sectionsGroupByLayer() {
        let base = Date()
        let sections = NoxTimelineBlockPresenter.makeSections(
            spans: [
                NoxActivitySpan(
                    id: "a1",
                    startedAt: base,
                    endedAt: base.addingTimeInterval(120),
                    appName: "Safari",
                    bundleId: "com.apple.Safari",
                    windowTitle: nil,
                    contextLabel: nil,
                    category: .research,
                    interruptions: 0,
                    focusScore: 0.2,
                    metadataJson: nil
                )
            ],
            focusBlocks: [],
            interruptions: [],
            semanticSpans: [],
            continuityThreads: []
        )
        #expect(sections.count == 1)
        #expect(sections.first?.layer == .activity)
    }
}
