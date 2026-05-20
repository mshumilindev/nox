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

@MainActor
final class NoxConnectorControlCoordinator {
    private let signalStore: NoxConnectorSignalStore
    private let behavioralSignalStore: NoxBehavioralIntelligenceSignalStore

    init(
        signalStore: NoxConnectorSignalStore,
        behavioralSignalStore: NoxBehavioralIntelligenceSignalStore
    ) {
        self.signalStore = signalStore
        self.behavioralSignalStore = behavioralSignalStore
    }

    func clearConnectorDerived() async throws {
        try await signalStore.clearConnectorDerived()
        try await behavioralSignalStore.clearDerived()
    }
}
