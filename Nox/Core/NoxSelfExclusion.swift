import Foundation

/// Nox must never appear in observation, memory, presence, or statistics.
nonisolated enum NoxSelfExclusion {
    static let analysisCategory: NoxAnalysisCategory = .systemInternal
    static var ownBundleId: String? {
        Bundle.main.bundleIdentifier
    }

    static func analysisCategory(bundleId: String?, appName: String? = nil) -> NoxAnalysisCategory {
        isExcluded(bundleId: bundleId, appName: appName) ? .systemInternal : .behavioral
    }

    static func isExcluded(bundleId: String?, appName: String? = nil) -> Bool {
        if let bundleId, let own = ownBundleId, bundleId == own {
            return true
        }
        if let appName, appName.caseInsensitiveCompare("Nox") == .orderedSame {
            return true
        }
        return false
    }

    static func shouldIgnore(snapshot: NoxActivitySnapshot) -> Bool {
        isExcluded(bundleId: snapshot.bundleId, appName: snapshot.appName)
    }

    static func shouldIgnore(record: NoxTimelineRecord) -> Bool {
        isExcluded(bundleId: record.bundleId, appName: record.appName)
    }

    static func shouldIgnore(event: NoxEvent) -> Bool {
        switch event.payload {
        case .appChanged(let payload):
            return isExcluded(bundleId: payload.bundleId, appName: payload.appName)
        case .windowChanged(let payload):
            return isExcluded(bundleId: payload.bundleId, appName: payload.appName)
        default:
            return false
        }
    }
}
