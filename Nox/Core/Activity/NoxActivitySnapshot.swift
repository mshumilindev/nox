import Foundation

nonisolated struct NoxActivitySnapshot: Equatable, Sendable {
    let appName: String
    let bundleId: String
    let windowTitle: String?
    /// Browser address bar / document URL from Accessibility when available.
    let documentURL: String?
    let processId: Int32?
    let idleSeconds: TimeInterval
    let isUserIdle: Bool
    let capturedAt: Date

    static let idleThresholdSeconds: TimeInterval = 120
    static let restingThresholdSeconds: TimeInterval = 600

    var isIdle: Bool {
        idleSeconds >= Self.idleThresholdSeconds
    }

    var isResting: Bool {
        idleSeconds >= Self.restingThresholdSeconds
    }
}
