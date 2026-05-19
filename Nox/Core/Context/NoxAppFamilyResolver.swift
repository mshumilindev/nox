import Foundation

enum NoxAppFamilyResolver {
    private static let browserBundles: Set<String> = [
        "com.apple.Safari", "company.thebrowser.Browser", "com.google.Chrome",
        "org.mozilla.firefox", "com.microsoft.edgemac", "com.brave.Browser",
        "com.operasoftware.Opera", "com.vivaldi.Vivaldi"
    ]

    private static let editorBundles: Set<String> = [
        "com.apple.dt.Xcode", "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92",
        "com.jetbrains.intellij", "com.jetbrains.pycharm", "com.jetbrains.webstorm",
        "com.sublimetext.4", "md.obsidian", "notion.id"
    ]

    private static let terminalBundles: Set<String> = [
        "com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable",
        "com.github.wez.wezterm", "io.alacritty"
    ]

    private static let mediaBundles: Set<String> = [
        "com.spotify.client", "com.apple.Music", "com.apple.TV", "org.videolan.vlc"
    ]

    private static let communicationBundles: Set<String> = [
        "com.tinyspeck.slackmacgap", "com.hnc.Discord", "ru.keepcoder.Telegram",
        "com.apple.mail", "com.apple.MobileSMS", "com.microsoft.teams2"
    ]

    private static let creativeBundles: Set<String> = [
        "com.adobe.Photoshop", "com.figma.Desktop", "com.apple.FinalCut", "com.apple.logic10"
    ]

    private static let gameMarkers = ["game", "steam", "epic", "battle.net", "minecraft", "unity"]

    static func resolve(bundleId: String, appName: String, category: NoxActivityCategory) -> NoxAppFamily {
        if browserBundles.contains(bundleId) { return .browser }
        if editorBundles.contains(bundleId) { return .editor }
        if terminalBundles.contains(bundleId) { return .terminal }
        if mediaBundles.contains(bundleId) { return .mediaPlayer }
        if communicationBundles.contains(bundleId) { return .communication }
        if creativeBundles.contains(bundleId) { return .creative }

        switch category {
        case .development: return .editor
        case .research: return .browser
        case .communication: return .communication
        case .creative: return .creative
        case .productivity: return .document
        case .passive: return .mediaPlayer
        case .entertainment: return .game
        case .system, .systemInternal: return .utility
        case .unknown, .general: break
        }

        let haystack = "\(bundleId) \(appName)".lowercased()
        if gameMarkers.contains(where: { haystack.contains($0) }) { return .game }
        if haystack.contains("finder") || haystack.contains("file") { return .fileManager }
        return .unknown
    }
}
