import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

nonisolated final class NoxActivityObserver: @unchecked Sendable {
    private let queue = DispatchQueue(label: "dev.nox.activity-observer", qos: .userInitiated)
    private let permissionService = NoxPermissionService()
    private let axFocusMonitor = NoxAXFocusMonitor()
    private var timer: DispatchSourceTimer?
    private var burstTimer: DispatchSourceTimer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []
    private var lastSnapshot: NoxActivitySnapshot?
    private var wasIdle = false
    private var onEvent: (@Sendable (NoxEvent) -> Void)?
    private var onSnapshot: (@Sendable (NoxActivitySnapshot) -> Void)?

    private let pollInterval: TimeInterval = 1.0
    private let burstPollInterval: TimeInterval = 0.25
    private let burstPollDuration: TimeInterval = 2.0

    func start(
        onEvent: @escaping @Sendable (NoxEvent) -> Void,
        onSnapshot: (@Sendable (NoxActivitySnapshot) -> Void)? = nil
    ) {
        self.onEvent = onEvent
        self.onSnapshot = onSnapshot
        queue.async { [weak self] in
            self?.registerNotifications()
            self?.startTimer()
            self?.startAXFocusMonitor()
            self?.emitCurrentSnapshot(force: true)
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
            self?.burstTimer?.cancel()
            self?.burstTimer = nil
            self?.axFocusMonitor.stop()
            self?.workspaceObservers.forEach { NotificationCenter.default.removeObserver($0) }
            self?.workspaceObservers.removeAll()
            self?.distributedObservers.forEach { DistributedNotificationCenter.default().removeObserver($0) }
            self?.distributedObservers.removeAll()
        }
    }

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
        timer.setEventHandler { [weak self] in
            self?.emitCurrentSnapshot(force: false)
        }
        timer.resume()
        self.timer = timer
    }

    private func startAXFocusMonitor() {
        axFocusMonitor.setEnabled(permissionService.currentState().accessibilityGranted) { [weak self] in
            guard let self else { return }
            self.queue.async {
                self.emitCurrentSnapshot(force: false)
                self.scheduleBurstPolling()
            }
        }
    }

    private func registerNotifications() {
        let workspace = NSWorkspace.shared
        let center = workspace.notificationCenter

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                let activatedPID = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?
                    .processIdentifier
                self?.handleApplicationActivated(activatedPID: activatedPID)
            }
        )

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.publishSystem(type: .systemWake, message: "Mac woke up")
            }
        )

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.publishSystem(type: .systemSleep, message: "Mac going to sleep")
            }
        )

        let distributed = DistributedNotificationCenter.default()
        distributedObservers.append(
            distributed.addObserver(
                forName: NSNotification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.publishSystem(type: .screenLocked, message: "Screen locked")
            }
        )
        distributedObservers.append(
            distributed.addObserver(
                forName: NSNotification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.publishSystem(type: .screenUnlocked, message: "Screen unlocked")
            }
        )
    }

    private func handleApplicationActivated(activatedPID: pid_t?) {
        queue.async { [weak self] in
            guard let self else { return }
            let permissions = self.permissionService.currentState()
            if let activatedPID {
                self.axFocusMonitor.frontmostApplicationChanged(
                    pid: activatedPID,
                    accessibilityGranted: permissions.accessibilityGranted
                )
            } else if let app = NSWorkspace.shared.frontmostApplication {
                self.axFocusMonitor.frontmostApplicationChanged(
                    pid: app.processIdentifier,
                    accessibilityGranted: permissions.accessibilityGranted
                )
            }
            self.emitCurrentSnapshot(force: false)
            self.scheduleBurstPolling()
            self.scheduleDeferredSnapshots()
        }
    }

    /// AX title/URL can lag briefly after app activation — re-read at short intervals.
    private func scheduleDeferredSnapshots() {
        let delays: [TimeInterval] = [0.08, 0.2, 0.45]
        for delay in delays {
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.emitCurrentSnapshot(force: false)
            }
        }
    }

    /// After app/window shift, poll faster briefly so tab/video context lands quickly.
    private func scheduleBurstPolling() {
        burstTimer?.cancel()
        let burst = DispatchSource.makeTimerSource(queue: queue)
        let maxTicks = max(1, Int(burstPollDuration / burstPollInterval))
        var ticks = 0
        burst.schedule(deadline: .now(), repeating: burstPollInterval)
        burst.setEventHandler { [weak self] in
            ticks += 1
            self?.emitCurrentSnapshot(force: false)
            if ticks >= maxTicks {
                burst.cancel()
                self?.burstTimer = nil
            }
        }
        burst.resume()
        burstTimer = burst
    }

    func refreshAccessibilityBridge() {
        queue.async { [weak self] in
            guard let self else { return }
            let granted = self.permissionService.currentState().accessibilityGranted
            self.axFocusMonitor.setEnabled(granted) { [weak self] in
                guard let self else { return }
                self.queue.async {
                    self.emitCurrentSnapshot(force: false)
                    self.scheduleBurstPolling()
                }
            }
            if granted, let app = NSWorkspace.shared.frontmostApplication {
                self.axFocusMonitor.frontmostApplicationChanged(
                    pid: app.processIdentifier,
                    accessibilityGranted: true
                )
            }
        }
    }

    private func publishSystem(type: NoxEventType, message: String) {
        let event = NoxEvent(
            type: type,
            payload: .system(SystemPayload(message: message))
        )
        onEvent?(event)
    }

    private func emitCurrentSnapshot(force: Bool) {
        let permissions = permissionService.currentState()
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleId = app.bundleIdentifier else {
            return
        }

        let appName = app.localizedName ?? bundleId

        if NoxSelfExclusion.isExcluded(bundleId: bundleId, appName: appName) {
            handleIdleOnlyTransition(idleSeconds: Self.systemIdleSeconds())
            return
        }

        let idleSeconds = Self.systemIdleSeconds()
        let isIdle = idleSeconds >= NoxActivitySnapshot.idleThresholdSeconds

        var windowTitle: String?
        var documentURL: String?
        if permissions.canReadWindowTitle {
            windowTitle = NoxWindowContextReader.focusedWindowTitle(
                for: bundleId,
                accessibilityGranted: permissions.accessibilityGranted
            )
            documentURL = NoxWindowContextReader.focusedDocumentURL(
                accessibilityGranted: permissions.accessibilityGranted
            )
        }
        if windowTitle == nil, permissions.screenRecordingGranted {
            windowTitle = NoxWindowContextReader.fallbackWindowTitle(for: bundleId)
        }

        let snapshot = NoxActivitySnapshot(
            appName: appName,
            bundleId: bundleId,
            windowTitle: windowTitle,
            documentURL: documentURL,
            processId: app.processIdentifier,
            idleSeconds: idleSeconds,
            isUserIdle: isIdle,
            capturedAt: Date()
        )

        handleIdleTransition(snapshot: snapshot)

        if let last = lastSnapshot, !force {
            if last.bundleId != snapshot.bundleId || last.appName != snapshot.appName {
                publishAppChange(from: last, to: snapshot)
                scheduleBurstPolling()
            } else if surfaceDidChange(from: last, to: snapshot) {
                publishWindowChange(from: last, to: snapshot)
                scheduleBurstPolling()
            }
        } else if force {
            publishAppChange(from: nil, to: snapshot)
        }

        if lastSnapshot?.bundleId != snapshot.bundleId || lastSnapshot?.processId != snapshot.processId {
            axFocusMonitor.frontmostApplicationChanged(
                pid: app.processIdentifier,
                accessibilityGranted: permissions.accessibilityGranted
            )
        }

        lastSnapshot = snapshot
        onSnapshot?(snapshot)
    }

    private func surfaceDidChange(from previous: NoxActivitySnapshot, to current: NoxActivitySnapshot) -> Bool {
        if previous.windowTitle != current.windowTitle {
            if let title = current.windowTitle, !title.isEmpty { return true }
            if previous.windowTitle != nil { return true }
        }
        if previous.documentURL != current.documentURL {
            if current.documentURL != nil { return true }
            if previous.documentURL != nil { return true }
        }
        return false
    }

    private func handleIdleOnlyTransition(idleSeconds: TimeInterval) {
        let isIdle = idleSeconds >= NoxActivitySnapshot.idleThresholdSeconds
        if isIdle, !wasIdle {
            wasIdle = true
            onEvent?(
                NoxEvent(
                    type: .userIdleStarted,
                    payload: .idle(IdlePayload(idleSeconds: idleSeconds))
                )
            )
        } else if !isIdle, wasIdle {
            wasIdle = false
            onEvent?(
                NoxEvent(
                    type: .userIdleEnded,
                    payload: .idle(IdlePayload(idleSeconds: idleSeconds))
                )
            )
        }
    }

    private func handleIdleTransition(snapshot: NoxActivitySnapshot) {
        if snapshot.isUserIdle, !wasIdle {
            wasIdle = true
            let event = NoxEvent(
                type: .userIdleStarted,
                payload: .idle(IdlePayload(idleSeconds: snapshot.idleSeconds))
            )
            onEvent?(event)
        } else if !snapshot.isUserIdle, wasIdle {
            wasIdle = false
            let event = NoxEvent(
                type: .userIdleEnded,
                payload: .idle(IdlePayload(idleSeconds: snapshot.idleSeconds))
            )
            onEvent?(event)
        }
    }

    private func publishAppChange(from previous: NoxActivitySnapshot?, to current: NoxActivitySnapshot) {
        let payload = AppChangedPayload(
            appName: current.appName,
            bundleId: current.bundleId,
            windowTitle: current.windowTitle,
            previousAppName: previous?.appName,
            previousBundleId: previous?.bundleId
        )
        onEvent?(NoxEvent(type: .appChanged, payload: .appChanged(payload)))
    }

    private func publishWindowChange(
        from previous: NoxActivitySnapshot,
        to current: NoxActivitySnapshot
    ) {
        let title = current.windowTitle
            ?? current.documentURL
            ?? previous.windowTitle
            ?? "Active window"
        let payload = WindowChangedPayload(
            appName: current.appName,
            bundleId: current.bundleId,
            windowTitle: title,
            previousWindowTitle: previous.windowTitle ?? previous.documentURL
        )
        onEvent?(NoxEvent(type: .windowChanged, payload: .windowChanged(payload)))
    }

    private static func systemIdleSeconds() -> TimeInterval {
        let types: [CGEventType] = [.keyDown, .mouseMoved, .leftMouseDown, .scrollWheel]
        return types.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }.max() ?? 0
    }
}
