import Foundation

struct NoxAppClassifier {
    func classify(bundleId: String, appName: String, windowTitle: String?) -> NoxActivityCategory {
        if NoxSelfExclusion.isExcluded(bundleId: bundleId, appName: appName) {
            return .systemInternal
        }
        if let byBundle = bundleCategory(bundleId) {
            if byBundle == .research, let title = windowTitle {
                return NoxTitleClassifier().refineBrowserCategory(title: title, defaultCategory: byBundle)
            }
            return byBundle
        }
        return inferredCategory(bundleId: bundleId, appName: appName, windowTitle: windowTitle)
    }

    private func bundleCategory(_ bundleId: String) -> NoxActivityCategory? {
        let development: Set<String> = [
            "com.apple.dt.Xcode",
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",
            "com.jetbrains.webstorm",
            "com.jetbrains.intellij",
            "com.jetbrains.pycharm",
            "com.jetbrains.rider",
            "com.jetbrains.clion",
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "dev.warp.Warp-Stable",
            "com.github.wez.wezterm",
            "io.alacritty",
            "org.vim.MacVim",
            "com.sublimetext.4",
            "com.barebones.bbedit",
            "com.github.GitHubClient",
            "com.docker.docker"
        ]
        let browsers: Set<String> = [
            "com.apple.Safari",
            "company.thebrowser.Browser",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi"
        ]
        let communication: Set<String> = [
            "com.tinyspeck.slackmacgap",
            "com.hnc.Discord",
            "ru.keepcoder.Telegram",
            "com.apple.mail",
            "com.apple.MobileSMS",
            "com.apple.iChat",
            "com.microsoft.teams2",
            "com.microsoft.teams",
            "us.zoom.xos",
            "com.cisco.webexmeetingsapp",
            "com.skype.skype",
            "net.whatsapp.WhatsApp",
            "com.facebook.archon",
            "com.google.meet"
        ]
        let entertainment: Set<String> = [
            "com.spotify.client",
            "com.apple.Music",
            "com.apple.TV",
            "com.netflix.Netflix",
            "com.elmedia.video",
            "org.videolan.vlc"
        ]
        let creative: Set<String> = [
            "com.adobe.Photoshop",
            "com.adobe.Illustrator",
            "com.adobe.InDesign",
            "com.adobe.PremierePro",
            "com.adobe.AfterEffects",
            "com.figma.Desktop",
            "com.bohemiancoding.sketch3",
            "com.seriflabs.affinityphoto2",
            "com.seriflabs.affinitydesigner2",
            "com.apple.FinalCut",
            "com.apple.logic10",
            "com.blackmagic-design.DaVinciResolve"
        ]
        let aiAssistants: Set<String> = [
            "com.openai.chat",
            "com.openai.codex",
            "com.anthropic.claude",
            "ai.perplexity.mac",
            "com.perplexity.mac",
            "com.openai.chatgpt",
            "com.poe.poe",
            "com.microsoft.copilot"
        ]
        let productivity: Set<String> = [
            "com.apple.Notes",
            "com.apple.reminders",
            "com.apple.iCal",
            "com.apple.TextEdit",
            "com.apple.Preview",
            "com.apple.iWork.Pages",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Keynote",
            "com.microsoft.Word",
            "com.microsoft.Excel",
            "com.microsoft.Powerpoint",
            "com.microsoft.Outlook",
            "com.todoist.mac.Todoist",
            "notion.id",
            "com.linear",
            "com.flexibits.fantastical2.mac",
            "md.obsidian"
        ]

        if development.contains(bundleId) { return .development }
        if aiAssistants.contains(bundleId) { return .research }
        if browsers.contains(bundleId) { return .research }
        if communication.contains(bundleId) { return .communication }
        if creative.contains(bundleId) { return .creative }
        if productivity.contains(bundleId) { return .productivity }
        if entertainment.contains(bundleId) { return .passive }
        if bundleId.hasPrefix("com.apple.") { return .system }
        return nil
    }

    private func inferredCategory(
        bundleId: String,
        appName: String,
        windowTitle: String?
    ) -> NoxActivityCategory {
        let text = "\(bundleId) \(appName) \(windowTitle ?? "")".lowercased()

        if containsAny(text, ["code", "terminal", "shell", "git", "docker", "kubernetes", "xcode"]) {
            return .development
        }
        if containsAny(text, ["figma", "sketch", "adobe", "photo", "design", "final cut", "logic pro"]) {
            return .creative
        }
        if containsAny(text, ["mail", "message", "slack", "telegram", "discord", "teams", "zoom", "meet"]) {
            return .communication
        }
        if containsAny(text, ["notes", "calendar", "document", "spreadsheet", "presentation", "notion", "obsidian"]) {
            return .productivity
        }
        if containsAny(text, ["music", "spotify", "video", "netflix", "youtube", "tv"]) {
            return .passive
        }
        if containsAny(text, ["torrent", "download", "magnet", "transmission", "qbittorrent", "bittorrent"]) {
            return .passive
        }
        if containsAny(text, ["game", "steam", "epic games", "battle.net", "minecraft", "roblox"]) {
            return .entertainment
        }
        if containsAny(text, ["browser", "safari", "chrome", "firefox", "edge", "brave"]) {
            return .research
        }
        if containsAny(text, [
            "openai", "chatgpt", "claude", "anthropic", "perplexity", "copilot", "gemini",
            "poe", "mistral", "llama", "deepseek"
        ]) {
            return .research
        }
        if containsAny(text, ["codex"]) {
            return .development
        }
        if !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .productivity
        }
        return .general
    }

    private func containsAny(_ text: String, _ markers: [String]) -> Bool {
        markers.contains { text.contains($0) }
    }
}
