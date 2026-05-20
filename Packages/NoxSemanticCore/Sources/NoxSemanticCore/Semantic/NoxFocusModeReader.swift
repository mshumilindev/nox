import Foundation
import NoxCore
import NoxContextCore

public enum NoxFocusModeHint: String, Equatable, Sendable {
    case unknown
    case work
    case personal
    case doNotDisturb
    case sleep
}

/// Best-effort Focus mode hint. macOS does not expose a stable public Focus API for sandboxed apps.
public enum NoxFocusModeReader {
    public static func currentHint() -> NoxFocusModeHint {
        .unknown
    }
}
