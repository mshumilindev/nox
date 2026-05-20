import Foundation

public enum NoxPresenceRules {
    static let productivityBundleIds: Set<String> = [
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.jetbrains.webstorm",
        "com.jetbrains.intellij",
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "company.thebrowser.Browser",
        "com.apple.Safari"
    ]

    static let devWindowTitleSignals: [String] = [
        "github",
        "stackoverflow",
        "localhost",
        "docs",
        "api",
        "pull request",
        "merge",
        "xcode",
        "swift"
    ]

    static let idleSeconds: TimeInterval = 120
    static let restingSeconds: TimeInterval = 600
    static let focusedSeconds: TimeInterval = 900
    static let flowSeconds: TimeInterval = 1800
    static let distractedSwitchCount = 6
    public static let distractedWindowSeconds: TimeInterval = 180
    static let focusedMaxSwitches = 2
    static let flowMaxSwitches = 1

    public static func isProductivityApp(bundleId: String, windowTitle: String?) -> Bool {
        if productivityBundleIds.contains(bundleId) {
            if bundleId == "com.apple.Safari" {
                return safariLooksLikeWork(windowTitle)
            }
            return true
        }
        return false
    }

    static func safariLooksLikeWork(_ windowTitle: String?) -> Bool {
        guard let title = windowTitle?.lowercased(), !title.isEmpty else { return false }
        return devWindowTitleSignals.contains { title.contains($0) }
    }
}
