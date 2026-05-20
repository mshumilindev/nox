import Foundation
import NoxCore

@MainActor
final class NoxContextObservationPipeline {
    private let activityObserver: NoxActivityObserver

    init(activityObserver: NoxActivityObserver = NoxActivityObserver()) {
        self.activityObserver = activityObserver
    }

    func start(
        publishEvent: @escaping @MainActor (NoxEvent) -> Void,
        ingestSnapshot: @escaping @MainActor (NoxActivitySnapshot) async -> Void
    ) {
        activityObserver.start(
            onEvent: { event in
                Task { @MainActor in
                    publishEvent(event)
                }
            },
            onSnapshot: { snapshot in
                Task { @MainActor in
                    await ingestSnapshot(snapshot)
                }
            }
        )
    }

    func stop() {
        activityObserver.stop()
    }

    func refreshAccessibilityBridge() {
        activityObserver.refreshAccessibilityBridge()
    }
}
