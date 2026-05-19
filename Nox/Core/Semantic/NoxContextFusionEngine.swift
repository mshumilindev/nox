import Foundation

struct NoxContextFusionResult: Equatable, Sendable {
    let label: NoxFusionLabel
    let confidence: Double
    let phrase: String
    let sensitivityLevel: NoxSensitivityLevel
    let supportingSignals: [NoxSemanticReason]
}

struct NoxContextFusionEngine {
    func fuse(context: NoxSemanticContext, browser: NoxBrowserContext) -> NoxContextFusionResult {
        var scores: [NoxFusionLabel: Double] = [:]
        var reasons: [NoxSemanticReason] = []

        let sensitivity = NoxSensitiveContextHandler.sensitivity(
            domain: context.domain ?? browser.domain,
            title: context.windowTitle,
            bundleId: context.bundleId
        )
        if browser.category == .privateBrowsing {
            return NoxContextFusionResult(
                label: .unknown,
                confidence: 0.88,
                phrase: "Private context",
                sensitivityLevel: .privateContext,
                supportingSignals: [
                    NoxSemanticReason(signal: "sensitivity", detail: "private browsing context")
                ]
            )
        }

        if sensitivity == .privateContext || sensitivity == .sensitive {
            return NoxContextFusionResult(
                label: .unknown,
                confidence: 0.85,
                phrase: sensitivity == .privateContext ? "Private context" : "Sensitive context",
                sensitivityLevel: sensitivity,
                supportingSignals: [
                    NoxSemanticReason(signal: "sensitivity", detail: "protected context")
                ]
            )
        }

        switch browser.category {
        case .travel:
            scores[.likelyTravelPlanning, default: 0] += 0.5
            reasons.append(NoxSemanticReason(signal: "domain", detail: "travel site active"))
        case .shopping:
            scores[.likelyShopping, default: 0] += 0.5
        case .entertainment:
            scores[.likelyPassiveEntertainment, default: 0] += 0.55
        case .development, .reference:
            scores[.likelyWorkRelated, default: 0] += 0.45
        case .research:
            scores[.likelyResearch, default: 0] += 0.5
        case .aiWorkflow:
            scores[.likelyAIAssistedWork, default: 0] += 0.45
        default:
            break
        }

        let appIntentScores = dynamicIntentScores(context: context)
        for (label, score) in appIntentScores {
            scores[label, default: 0] += score
        }

        if context.metrics.isPassive {
            scores[.likelyPassiveEntertainment, default: 0] += 0.2
        }

        if appIntentScores.isEmpty, isSustainedPassiveContext(context, browser: browser) {
            scores[.likelyPassiveEntertainment, default: 0] += 0.48
            reasons.append(NoxSemanticReason(signal: "interaction_shape", detail: "sustained low-interaction context"))
        }

        if context.recentSwitchCount >= 4 {
            reasons.append(NoxSemanticReason(signal: "switching", detail: "high app switching"))
        }

        if context.focusHint == .work {
            scores[.likelyWorkRelated, default: 0] += 0.15
        } else if context.focusHint == .personal {
            scores[.possiblyPersonal, default: 0] += 0.15
        }

        if hasDevApps(context) && context.metrics.isWritingHeavy {
            scores[.likelyWorkRelated, default: 0] += 0.35
            scores[.likelyAIAssistedWork, default: 0] += 0.15
        }

        guard let best = scores.max(by: { $0.value < $1.value }), best.value > 0.2 else {
            return NoxContextFusionResult(
                label: .unknown,
                confidence: 0.2,
                phrase: "",
                sensitivityLevel: sensitivity,
                supportingSignals: reasons
            )
        }

        let confidence = min(0.9, best.value + browser.confidence * 0.25)
        let phrase = fusionPhrase(label: best.key)
        return NoxContextFusionResult(
            label: best.key,
            confidence: confidence,
            phrase: phrase,
            sensitivityLevel: sensitivity,
            supportingSignals: reasons
        )
    }

    private func hasDevApps(_ context: NoxSemanticContext) -> Bool {
        let dev = ["com.apple.dt.Xcode", "com.apple.Terminal", "com.todesktop.230313mzl4w4u92"]
        if let id = context.bundleId, dev.contains(id) { return true }
        return context.nearbyBundleIds.contains(where: { dev.contains($0) })
    }

    private func isSustainedPassiveContext(_ context: NoxSemanticContext, browser: NoxBrowserContext) -> Bool {
        let unclearBrowser = browser.category == .ambiguous || browser.category == .unknown
        let browserOrUnknown = unclearBrowser || context.browserCategory == .ambiguous || context.browserCategory == .unknown
        guard browserOrUnknown,
              context.timeInCurrentApp >= 30,
              !context.metrics.isWritingHeavy,
              context.metrics.scrollIntensity < 1.5,
              context.metrics.typingDensity < 0.8,
              context.metrics.mouseDensity < 2.5
        else { return false }
        return context.metrics.isPassive || context.idleSeconds >= 20 || !context.metrics.isInteractionActive
    }

    private func fusionPhrase(label: NoxFusionLabel) -> String {
        switch label {
        case .likelyWorkRelated: return "Sustained focus"
        case .possiblyPersonal: return "Personal context"
        case .likelyResearch: return "Research browsing"
        case .likelyTravelPlanning: return "Travel planning"
        case .likelyShopping: return "Shopping"
        case .likelyPassiveEntertainment: return "Passive viewing"
        case .likelyAIAssistedWork: return "AI-assisted work"
        case .likelyFileTransfer: return "File transfer"
        case .likelyGaming: return "Game session"
        case .likelyCreativeWork: return "Creative work"
        case .likelyCommunication: return "Conversation"
        case .likelyInteractiveBrowsing: return "Interactive browsing"
        case .unknown: return ""
        }
    }

    private func dynamicIntentScores(context: NoxSemanticContext) -> [NoxFusionLabel: Double] {
        let text = [
            context.bundleId,
            context.appName,
            context.windowTitle,
            context.domain
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let tokens = Set(text.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 })
        var scores: [NoxFusionLabel: Double] = [:]

        score(
            &scores,
            label: .likelyFileTransfer,
            tokens: tokens,
            text: text,
            markers: [
                "torrent", "torrents", "magnet", "download", "downloads", "upload", "uploads",
                "transfer", "transmission", "qbittorrent", "utorrent", "bittorrent", "seed",
                "seeding", "leeching", "aria2", "jdownloader", "ftp", "sftp"
            ],
            phrases: ["file transfer", "download manager", "magnet link", "download queue"]
        )

        score(
            &scores,
            label: .likelyGaming,
            tokens: tokens,
            text: text,
            markers: [
                "game", "games", "steam", "epic", "battle", "launcher", "playstation",
                "xbox", "minecraft", "roblox", "unity", "unreal", "arcade", "flash",
                "itch", "rpg", "fps", "puzzle", "simulator"
            ],
            phrases: ["game launcher", "playing game", "flash game", "browser game"]
        )

        score(
            &scores,
            label: .likelyPassiveEntertainment,
            tokens: tokens,
            text: text,
            markers: [
                "player", "movie", "film", "episode", "series", "season", "watch", "video",
                "vlc", "iina", "plex", "jellyfin", "infuse", "music", "spotify", "podcast"
            ],
            phrases: ["now playing", "media player", "watch now"]
        )

        score(
            &scores,
            label: .likelyCreativeWork,
            tokens: tokens,
            text: text,
            markers: [
                "design", "canvas", "photo", "image", "video", "audio", "timeline",
                "figma", "sketch", "photoshop", "illustrator", "premiere", "resolve",
                "logic", "garageband", "blender"
            ],
            phrases: ["color correction", "video edit", "audio edit"]
        )

        score(
            &scores,
            label: .likelyCommunication,
            tokens: tokens,
            text: text,
            markers: [
                "chat", "message", "messages", "mail", "inbox", "meeting", "call",
                "zoom", "slack", "discord", "telegram", "whatsapp"
            ],
            phrases: ["video call", "direct message"]
        )

        if context.metrics.mouseDensity >= 4 &&
            context.metrics.typingDensity < 1.2 &&
            context.metrics.scrollIntensity < 2 &&
            context.metrics.isInteractionActive &&
            (context.browserCategory == .ambiguous || context.browserCategory == .unknown) {
            scores[.likelyInteractiveBrowsing, default: 0] += 0.48
        }

        return scores.filter { $0.value >= 0.45 }
    }

    private func score(
        _ scores: inout [NoxFusionLabel: Double],
        label: NoxFusionLabel,
        tokens: Set<String>,
        text: String,
        markers: Set<String>,
        phrases: Set<String>
    ) {
        var value = 0.0
        for marker in markers where tokens.contains(marker) {
            value += 0.22
        }
        for phrase in phrases where text.contains(phrase) {
            value += 0.35
        }
        if value > 0 {
            scores[label, default: 0] += min(0.65, value)
        }
    }
}
