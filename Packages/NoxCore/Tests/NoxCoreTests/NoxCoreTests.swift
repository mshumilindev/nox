import Foundation
import NoxCore
import Testing

struct NoxPresenceStatePackageTests {
    @Test func presenceTitlesExist() {
        for state in NoxPresenceState.allCases {
            #expect(!state.title.isEmpty)
            #expect(!state.symbolName.isEmpty)
        }
    }
}

struct NoxTitleSanitizerPackageTests {
    @Test func stripsCursorSuffix() {
        let result = NoxTitleSanitizer.sanitize(
            appName: "Cursor",
            windowTitle: "shipwise — Cursor — Edited"
        )
        #expect(result == "shipwise")
    }
}

struct NoxPhilosophyPackageTests {
    @Test func mottoPhasesAreStable() {
        #expect(NoxPhilosophy.inline == "I perform. I rest. I live. I am.")
        #expect(NoxPhilosophy.phases.count == 4)
    }

    @Test func restingPresenceEmphasizesRest() {
        let emphasis = NoxPhilosophy.emphasis(for: .resting)
        #expect(emphasis == .rest)
        #expect(NoxPhilosophy.lineOpacity(for: .rest, emphasis: emphasis) >
                NoxPhilosophy.lineOpacity(for: .perform, emphasis: emphasis))
    }

    @Test func focusedPresenceEmphasizesPerform() {
        let emphasis = NoxPhilosophy.emphasis(for: .flow)
        #expect(emphasis == .perform)
        #expect(NoxPhilosophy.lineOpacity(for: .perform, emphasis: emphasis) >
                NoxPhilosophy.lineOpacity(for: .rest, emphasis: emphasis))
    }
}

struct NoxActivitySnapshotPackageTests {
    @Test func observationSurfaceIgnoresCapturedAt() {
        let a = NoxActivitySnapshot(
            appName: "Xcode",
            bundleId: "com.apple.dt.Xcode",
            windowTitle: "Nox",
            documentURL: nil,
            processId: 1,
            idleSeconds: 10,
            isUserIdle: false,
            capturedAt: Date()
        )
        let b = NoxActivitySnapshot(
            appName: "Xcode",
            bundleId: "com.apple.dt.Xcode",
            windowTitle: "Nox",
            documentURL: nil,
            processId: 1,
            idleSeconds: 15,
            isUserIdle: false,
            capturedAt: Date().addingTimeInterval(5)
        )
        #expect(a.hasSameObservationSurface(as: b))
    }

    @Test func idleBucketChangesSurface() {
        let active = NoxActivitySnapshot(
            appName: "Xcode",
            bundleId: "x",
            windowTitle: nil,
            documentURL: nil,
            processId: 1,
            idleSeconds: 10,
            isUserIdle: false,
            capturedAt: Date()
        )
        let idle = NoxActivitySnapshot(
            appName: "Xcode",
            bundleId: "x",
            windowTitle: nil,
            documentURL: nil,
            processId: 1,
            idleSeconds: 150,
            isUserIdle: true,
            capturedAt: Date()
        )
        #expect(!active.hasSameObservationSurface(as: idle))
    }
}

struct NoxEmotionalSafetyCopyPackageTests {
    @Test func emotionalSafetyBlocksManipulativeCopy() {
        #expect(!NoxEmotionalSafetyCopy.isAllowed("You were productive yesterday!"))
        #expect(NoxEmotionalSafetyCopy.sanitize("Stay focused on your goals") != "Stay focused on your goals")
    }
}
