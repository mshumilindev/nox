import Foundation

@MainActor
final class NoxConnectorControlCoordinator {
    private let signalStore: NoxConnectorSignalStore

    init(signalStore: NoxConnectorSignalStore) {
        self.signalStore = signalStore
    }

    func clearConnectorDerived() async throws {
        try await signalStore.clearConnectorDerived()
    }
}
