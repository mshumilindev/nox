import Foundation
import NoxCore

@MainActor
final class NoxContextEventPipeline {
    private let eventBus = NoxEventBus()
    private var eventBusSubscriptionID: UUID?
    private var permissionPollingTask: Task<Void, Never>?
    private var interactionSamplingTask: Task<Void, Never>?
    private var semanticHeartbeatTask: Task<Void, Never>?
    private var maintenanceStartupTask: Task<Void, Never>?
    private var maintenanceLoopTask: Task<Void, Never>?

    func publish(_ event: NoxEvent) {
        eventBus.publish(event)
    }

    func startEventHandling(_ handle: @escaping @MainActor (NoxEvent) async -> Void) {
        eventBusSubscriptionID = eventBus.subscribe { event in
            Task { @MainActor in
                await handle(event)
            }
        }
    }

    func startPermissionPolling(refresh: @escaping @MainActor () -> Void) {
        permissionPollingTask?.cancel()
        permissionPollingTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                refresh()
            }
        }
    }

    func startInteractionSampling(sample: @escaping @MainActor (@escaping (NoxEvent) -> Void) -> Void) {
        interactionSamplingTask?.cancel()
        interactionSamplingTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                sample { [weak self] event in
                    self?.publish(event)
                }
            }
        }
    }

    func startSemanticHeartbeat(_ tick: @escaping @MainActor () async -> Void) {
        semanticHeartbeatTask?.cancel()
        semanticHeartbeatTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await tick()
            }
        }
    }

    func scheduleStartupMaintenance(_ run: @escaping @MainActor () async -> Void) {
        maintenanceStartupTask?.cancel()
        maintenanceStartupTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(45))
            guard !Task.isCancelled else { return }
            await run()
        }
    }

    func startMaintenanceLoop(
        intervalSeconds: TimeInterval,
        run: @escaping @MainActor () async -> Void
    ) {
        maintenanceLoopTask?.cancel()
        maintenanceLoopTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds))
                guard !Task.isCancelled else { return }
                await run()
            }
        }
    }

    func stop() {
        eventBusSubscriptionID = nil
        permissionPollingTask?.cancel()
        interactionSamplingTask?.cancel()
        semanticHeartbeatTask?.cancel()
        maintenanceStartupTask?.cancel()
        maintenanceLoopTask?.cancel()
    }

    func diagnosticsSnapshot(
        panelOpen: Bool,
        presencePageActive: Bool,
        liveSignalBufferSize: Int,
        recentBundleBufferSize: Int
    ) -> NoxPerformanceDiagnosticsSnapshot {
        NoxPerformanceDiagnostics.snapshot(
            panelOpen: panelOpen,
            presencePageActive: presencePageActive,
            permissionPollingActive: permissionPollingTask?.isCancelled == false,
            interactionSamplingActive: interactionSamplingTask?.isCancelled == false,
            semanticHeartbeatActive: semanticHeartbeatTask?.isCancelled == false,
            maintenanceLoopActive: maintenanceLoopTask?.isCancelled == false,
            liveSignalBufferSize: liveSignalBufferSize,
            recentBundleBufferSize: recentBundleBufferSize
        )
    }
}
