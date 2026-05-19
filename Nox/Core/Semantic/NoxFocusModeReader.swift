import Foundation

enum NoxFocusModeHint: String, Equatable, Sendable {
    case unknown
    case work
    case personal
    case doNotDisturb
    case sleep
}

/// Best-effort Focus mode hint. macOS does not expose a stable public Focus API for sandboxed apps.
enum NoxFocusModeReader {
    static func currentHint() -> NoxFocusModeHint {
        .unknown
    }
}
