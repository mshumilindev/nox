import Foundation
import os

/// Dev-only mesh diagnostics — never shown in normal UI.
nonisolated enum NoxPresenceMeshDiagnostics {
    private static let logger = Logger(subsystem: "dev.nox.Nox", category: "PresenceMesh")

    #if DEBUG
    private static var buffer: [String] = []
    private static let maxLines = 200
    #endif

    static var recentLines: [String] {
        #if DEBUG
        return buffer
        #else
        return []
        #endif
    }

    static func log(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        #if DEBUG
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)"
        buffer.append(line)
        if buffer.count > maxLines {
            buffer.removeFirst(buffer.count - maxLines)
        }
        #endif
    }
}
