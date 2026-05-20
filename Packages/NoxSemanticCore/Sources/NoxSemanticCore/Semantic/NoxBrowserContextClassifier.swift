import Foundation
import NoxCore
import NoxContextCore

public struct NoxBrowserContext {
    public let category: NoxBrowserCategory
    public let confidence: Double
    public let domain: String?
    public let isAmbiguous: Bool
}

public struct NoxBrowserContextClassifier {
    public init() {}

    private let domainClassifier = NoxDomainClassifier()

    public func classify(
        bundleId: String?,
        windowTitle: String?,
        domain: String? = nil
    ) -> NoxBrowserContext {
        let resolvedDomain = domain ?? domainClassifier.domain(from: windowTitle)
        let host = resolvedDomain?.lowercased() ?? ""
        let title = windowTitle?.lowercased() ?? ""

        let sensitivity = NoxSensitiveContextHandler.sensitivity(
            domain: host,
            title: windowTitle,
            bundleId: bundleId
        )
        if sensitivity == .privateContext {
            return NoxBrowserContext(
                category: .privateBrowsing,
                confidence: 0.9,
                domain: nil,
                isAmbiguous: false
            )
        }
        if sensitivity == .sensitive {
            return NoxBrowserContext(
                category: .sensitive,
                confidence: 0.85,
                domain: nil,
                isAmbiguous: false
            )
        }

        if let match = matchHost(host, title: title) {
            return match
        }

        if isBrowser(bundleId) {
            return NoxBrowserContext(
                category: .ambiguous,
                confidence: 0.35,
                domain: resolvedDomain,
                isAmbiguous: true
            )
        }

        return NoxBrowserContext(
            category: .unknown,
            confidence: 0.2,
            domain: resolvedDomain,
            isAmbiguous: true
        )
    }

    private func matchHost(_ host: String, title: String) -> NoxBrowserContext? {
        if host.isEmpty {
            return titleMatch(title)
        }

        let rules: [(Set<String>, NoxBrowserCategory, Double)] = [
            (["github.com", "gitlab.com", "bitbucket.org"], .development, 0.88),
            (["developer.apple.com", "docs.swift.org", "stackoverflow.com"], .reference, 0.82),
            (["docs.", "readthedocs.io", "developer.mozilla.org", "wikipedia.org"], .reference, 0.72),
            (["openai.com", "platform.openai.com"], .research, 0.75),
            (["chatgpt.com", "chat.openai.com"], .aiWorkflow, 0.8),
            (["claude.ai", "anthropic.com"], .aiWorkflow, 0.78),
            (["gemini.google.com", "perplexity.ai", "poe.com", "copilot.microsoft.com"], .aiWorkflow, 0.74),
            (["cursor.com", "cursor.sh"], .aiWorkflow, 0.7),
            (["booking.com", "airbnb.com", "ryanair.com", "wizzair.com", "kayak.com"], .travel, 0.86),
            ([
                "expedia.", "skyscanner.", "google.com/travel", "maps.google.", "trip.com",
                "hotels.com", "hostelworld.com", "agoda.com", "trivago.", "momondo.",
                "kiwi.com", "omio.com", "trainline.", "flixbus.", "uber.com", "bolt.eu"
            ], .travel, 0.78),
            ([
                "amazon.", "allegro.", "zalando.", "etsy.com", "ebay.", "shopify.",
                "apple.com/shop", "store.steampowered.com", "ikea.", "temu.", "aliexpress."
            ], .shopping, 0.84),
            ([
                "netflix.com", "disneyplus.com", "primevideo.com", "max.com", "hbomax.com",
                "play.hbomax.com", "hbo.com", "hulu.com", "appletv.apple.com",
                "tv.apple.com", "paramountplus.com", "peacocktv.com", "twitch.tv"
            ], .entertainment, 0.88),
            (["youtube.com", "youtu.be", "m.youtube.com", "music.youtube.com"], .entertainment, 0.9),
            (["reddit.com"], .ambiguous, 0.42),
            (["tripadvisor.", "trustpilot.", "yelp."], .reviews, 0.8),
            (["allrecipes.com", "bbcgoodfood.com", "cookpad.com", "seriouseats.com"], .recipes, 0.82),
            (["slack.com", "discord.com", "teams.microsoft.", "meet.google.", "zoom.us"], .communication, 0.75),
            (["twitter.com", "x.com", "instagram.com", "facebook.com", "linkedin.com"], .social, 0.72),
            (["notion.so", "linear.app", "atlassian.net", "docs.google.com"], .reference, 0.65)
        ]

        for (hosts, category, confidence) in rules {
            if hosts.contains(where: { host.contains($0) }) {
                return NoxBrowserContext(
                    category: category,
                    confidence: confidence,
                    domain: host,
                    isAmbiguous: category == .ambiguous
                )
            }
        }

        if let dynamic = dynamicMatch(host: host, title: title) {
            return dynamic
        }

        if host.contains("google.") && (title.contains("flight") || title.contains("travel")) {
            return NoxBrowserContext(category: .travel, confidence: 0.7, domain: host, isAmbiguous: false)
        }

        return nil
    }

    private func titleMatch(_ title: String) -> NoxBrowserContext? {
        if title.contains("chatgpt") || title.contains("claude") || title.contains("perplexity") {
            return NoxBrowserContext(category: .aiWorkflow, confidence: 0.62, domain: nil, isAmbiguous: false)
        }
        if title.contains("github") || title.contains("pull request") || title.contains("repository") {
            return NoxBrowserContext(category: .development, confidence: 0.65, domain: nil, isAmbiguous: false)
        }
        if title.contains("docs") || title.contains("documentation") || title.contains("api") {
            return NoxBrowserContext(category: .reference, confidence: 0.58, domain: nil, isAmbiguous: false)
        }
        if title.contains("flight") ||
            title.contains("hotel") ||
            title.contains("airbnb") ||
            title.contains("booking") ||
            title.contains("tickets") ||
            title.contains("maps") {
            return NoxBrowserContext(category: .travel, confidence: 0.62, domain: nil, isAmbiguous: false)
        }
        if title.contains("cart") ||
            title.contains("checkout") ||
            title.contains("amazon") ||
            title.contains("order") ||
            title.contains("shop") {
            return NoxBrowserContext(category: .shopping, confidence: 0.58, domain: nil, isAmbiguous: false)
        }
        if title.contains("recipe") || title.contains("cook") {
            return NoxBrowserContext(category: .recipes, confidence: 0.55, domain: nil, isAmbiguous: false)
        }
        if title.contains("review") {
            return NoxBrowserContext(category: .reviews, confidence: 0.55, domain: nil, isAmbiguous: false)
        }
        if title.contains("youtube") ||
            title.contains("netflix") ||
            title.contains("hbo max") ||
            title.contains("hbomax") ||
            title.contains("prime video") ||
            title.contains("disney+") {
            return NoxBrowserContext(category: .entertainment, confidence: 0.55, domain: nil, isAmbiguous: false)
        }
        return nil
    }

    private func dynamicMatch(host: String, title: String) -> NoxBrowserContext? {
        let text = "\(host) \(title)"
        let tokens = tokenSet(from: text)

        let categoryScores: [(NoxBrowserCategory, Double)] = [
            (.entertainment, score(
                tokens: tokens,
                text: text,
                markers: [
                    "watch", "video", "stream", "streaming", "movie", "film", "episode",
                    "series", "season", "player", "play", "live", "tv", "cinema", "trailer",
                    "anime", "vod", "show"
                ],
                phrases: ["now playing", "watch now", "continue watching", "full movie"]
            )),
            (.travel, score(
                tokens: tokens,
                text: text,
                markers: [
                    "flight", "flights", "hotel", "hotels", "hostel", "stay", "booking",
                    "reservation", "trip", "travel", "map", "maps", "route", "ticket",
                    "tickets", "train", "bus", "airline", "airport", "checkin", "check-in"
                ],
                phrases: ["select flight", "room availability", "book a stay", "boarding pass"]
            )),
            (.shopping, score(
                tokens: tokens,
                text: text,
                markers: [
                    "cart", "checkout", "basket", "product", "products", "shop", "store",
                    "buy", "price", "order", "delivery", "sale", "wishlist", "coupon"
                ],
                phrases: ["add to cart", "place order", "payment method"]
            )),
            (.reference, score(
                tokens: tokens,
                text: text,
                markers: [
                    "docs", "documentation", "api", "reference", "manual", "guide",
                    "learn", "tutorial", "handbook", "spec", "sdk"
                ],
                phrases: ["getting started", "api reference", "developer docs"]
            )),
            (.development, score(
                tokens: tokens,
                text: text,
                markers: [
                    "repo", "repository", "pull", "merge", "commit", "branch", "issue",
                    "debug", "deploy", "build", "ci", "release"
                ],
                phrases: ["pull request", "merge request", "build failed"]
            )),
            (.reviews, score(
                tokens: tokens,
                text: text,
                markers: ["review", "reviews", "rating", "ratings", "compare", "comparison"],
                phrases: ["customer reviews", "best rated"]
            )),
            (.communication, score(
                tokens: tokens,
                text: text,
                markers: ["chat", "message", "messages", "inbox", "mail", "meeting", "call"],
                phrases: ["direct message", "video call"]
            )),
            (.research, score(
                tokens: tokens,
                text: text,
                markers: ["paper", "papers", "research", "study", "journal", "arxiv", "abstract"],
                phrases: ["research paper", "case study"]
            )),
            (.social, score(
                tokens: tokens,
                text: text,
                markers: ["feed", "profile", "post", "posts", "followers", "following"],
                phrases: ["social feed"]
            ))
        ]

        guard let best = categoryScores.max(by: { $0.1 < $1.1 }), best.1 >= 2 else {
            return nil
        }

        let confidence = min(0.74, 0.42 + best.1 * 0.08)
        return NoxBrowserContext(
            category: best.0,
            confidence: confidence,
            domain: host,
            isAmbiguous: confidence < 0.55
        )
    }

    private func score(
        tokens: Set<String>,
        text: String,
        markers: Set<String>,
        phrases: Set<String>
    ) -> Double {
        var value = 0.0
        for marker in markers where tokens.contains(marker) {
            value += 1
        }
        for phrase in phrases where text.contains(phrase) {
            value += 1.5
        }
        return value
    }

    private func tokenSet(from text: String) -> Set<String> {
        Set(
            text
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 1 }
        )
    }

    private func isBrowser(_ bundleId: String?) -> Bool {
        guard let bundleId else { return false }
        return [
            "com.apple.Safari",
            "com.google.Chrome",
            "company.thebrowser.Browser",
            "org.mozilla.firefox",
            "com.microsoft.edgemac"
        ].contains(bundleId)
    }
}
