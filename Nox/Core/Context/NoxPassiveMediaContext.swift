import Foundation

/// Shared rules for passive video/audio vs reading-shaped browser activity.
enum NoxPassiveMediaContext {
    static func indicatesPassiveMedia(
        title: String?,
        domain: String?,
        browserCategory: NoxBrowserCategory?
    ) -> Bool {
        if NoxTitleTokenAnalyzer.indicatesPassiveMedia(title: title) { return true }
        if browserCategory == .entertainment { return true }
        guard let host = domain?.lowercased(), !host.isEmpty else { return false }
        return isStreamingHost(host)
    }

    static func isStreamingHost(_ host: String) -> Bool {
        let markers = [
            "youtube.", "youtu.be", "netflix.", "disneyplus.", "primevideo.",
            "twitch.", "hbomax.", "hulu.", "spotify.", "music.apple.com",
            "tv.apple.com", "vimeo.", "dailymotion."
        ]
        return markers.contains { host.contains($0) }
    }
}
