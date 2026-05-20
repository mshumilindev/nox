import Foundation

/// Nox must never appear in observation, memory, presence, or statistics.
public nonisolated enum NoxSelfExclusion {
    public static let analysisCategory: NoxAnalysisCategory = .systemInternal

    /// Set from the macOS app at launch (`Bundle.main.bundleIdentifier`).
    public static var ownBundleId: String?

    public static func analysisCategory(bundleId: String?, appName: String? = nil) -> NoxAnalysisCategory {
        isExcluded(bundleId: bundleId, appName: appName) ? .systemInternal : .behavioral
    }

    public static func isExcluded(bundleId: String?, appName: String? = nil) -> Bool {
        if let bundleId, let own = ownBundleId, bundleId == own {
            return true
        }
        if let appName, appName.caseInsensitiveCompare("Nox") == .orderedSame {
            return true
        }
        return false
    }

    public static func shouldIgnore(snapshot: NoxActivitySnapshot) -> Bool {
        isExcluded(bundleId: snapshot.bundleId, appName: snapshot.appName)
    }

    public static func shouldIgnore(event: NoxEvent) -> Bool {
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
