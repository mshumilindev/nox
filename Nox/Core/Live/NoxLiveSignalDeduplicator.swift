import Foundation

enum NoxLiveSignalDeduplicator {
    private static let nearDuplicateWindow: TimeInterval = 25

    static func shouldAccept(_ signal: NoxLiveSignal, in existing: [NoxLiveSignal]) -> Bool {
        if let first = existing.first,
           first.text == signal.text,
           signal.timestamp.timeIntervalSince(first.timestamp) < 2 {
            return false
        }

        let recent = existing.prefix(8)

        if signal.kind == .app, isRedundantAppSignal(signal, recent: Array(recent)) {
            return false
        }

        if signal.kind == .awareness, isRedundantBootstrap(signal, recent: Array(recent)) {
            return false
        }

        return true
    }

    static func isSelfApp(bundleId: String?) -> Bool {
        NoxSelfExclusion.isExcluded(bundleId: bundleId)
    }

    private static func isRedundantAppSignal(_ signal: NoxLiveSignal, recent: [NoxLiveSignal]) -> Bool {
        let appKey = extractAppKey(from: signal.text)

        for prior in recent where prior.kind == .app {
            let delta = signal.timestamp.timeIntervalSince(prior.timestamp)
            guard delta >= 0, delta < nearDuplicateWindow else { continue }

            let priorKey = extractAppKey(from: prior.text)
            if prior.text == signal.text { return true }

            if let appKey, let priorKey, appKey == priorKey {
                if signal.text.hasSuffix(" active"), isSwitchOrOpen(prior.text) {
                    return true
                }
                if isSwitchOrOpen(signal.text), prior.text.hasSuffix(" active") {
                    return true
                }
            }
        }

        return false
    }

    private static func isRedundantBootstrap(_ signal: NoxLiveSignal, recent: [NoxLiveSignal]) -> Bool {
        guard signal.text == "Watching quietly" else { return false }
        return recent.contains { $0.kind == .app || $0.kind == .window }
    }

    private static func isSwitchOrOpen(_ text: String) -> Bool {
        text.hasPrefix("Switched to ") || text.hasPrefix("Opened ")
    }

    private static func extractAppKey(from text: String) -> String? {
        if text.hasPrefix("Switched to ") {
            return String(text.dropFirst("Switched to ".count))
        }
        if text.hasPrefix("Opened ") {
            return String(text.dropFirst("Opened ".count))
        }
        if text.hasSuffix(" active") {
            return String(text.dropLast(" active".count))
        }
        if text.hasPrefix("Returned to ") {
            return String(text.dropFirst("Returned to ".count))
        }
        return nil
    }
}
