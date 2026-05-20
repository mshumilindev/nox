import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxForegroundIntentModel {
    static func intent(for snapshot: NoxActivitySnapshot) -> NoxForegroundIntent {
        let bundle = snapshot.bundleId.lowercased()
        let app = snapshot.appName.lowercased()

        if isLowContinuityUtility(bundle: bundle, app: app) {
            return NoxForegroundIntent(
                continuityWeight: 0.25,
                softThreshold: 3.0,
                hardThreshold: 12.0,
                requiresLongerStabilization: true
            )
        }

        if isHighContinuityApp(bundle: bundle, app: app) {
            return NoxForegroundIntent(
                continuityWeight: 0.85,
                softThreshold: 1.5,
                hardThreshold: 5.0,
                requiresLongerStabilization: false
            )
        }

        if isBrowser(bundle: bundle) {
            return NoxForegroundIntent(
                continuityWeight: 0.65,
                softThreshold: 2.0,
                hardThreshold: 6.5,
                requiresLongerStabilization: false
            )
        }

        return .standard
    }

    private static func isLowContinuityUtility(bundle: String, app: String) -> Bool {
        bundle == "com.apple.finder"
            || bundle == "com.apple.systempreferences"
            || bundle == "com.apple.systemsettings"
            || bundle.contains("raycast")
            || bundle.contains("alfred")
            || bundle.contains("launchbar")
            || app == "finder"
            || app.contains("spotlight")
            || app.contains("raycast")
            || app.contains("system settings")
    }

    private static func isHighContinuityApp(bundle: String, app: String) -> Bool {
        bundle.contains("xcode")
            || bundle.contains("cursor")
            || bundle.contains("visualstudiocode")
            || bundle.contains("terminal")
            || bundle.contains("iterm")
            || bundle.contains("warp")
            || bundle.contains("zed")
            || bundle.contains("figma")
            || bundle.contains("obsidian")
            || bundle.contains("ulysses")
            || bundle.contains("notion")
            || app.contains("cursor")
            || app.contains("xcode")
            || app.contains("terminal")
            || app.contains("figma")
    }

    private static func isBrowser(bundle: String) -> Bool {
        bundle.contains("safari")
            || bundle.contains("chrome")
            || bundle.contains("firefox")
            || bundle.contains("arc")
            || bundle.contains("brave")
    }
}
