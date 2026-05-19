import Foundation

struct NoxContextAdapterRegistry: Sendable {
    private let adapters: [any NoxContextAdapter]

    init(adapters: [any NoxContextAdapter] = NoxContextAdapterRegistry.defaultAdapters) {
        self.adapters = adapters.sorted { $0.priority > $1.priority }
    }

    /// Iteration 6A adapter set — capability-aware, shape-based, no site hardcoding.
    static let defaultAdapters: [any NoxContextAdapter] = [
        NoxTerminalLikeContextAdapter(),
        NoxEditorLikeContextAdapter(),
        NoxBrowserLikeContextAdapter(),
        NoxCommunicationLikeContextAdapter(),
        NoxCreativeLikeContextAdapter(),
        NoxMediaLikeContextAdapter(),
        NoxGameContextAdapter(),
        NoxFileTransferContextAdapter(),
        NoxGenericAppContextAdapter(),
        NoxUnknownFallbackContextAdapter()
    ]

    func collectEvidence(input: NoxContextAdapterInput) -> [NoxContextAdapterEvidence] {
        var results: [NoxContextAdapterEvidence] = []
        var fallback: NoxContextAdapterEvidence?

        for adapter in adapters {
            guard adapter.matches(input: input) else { continue }
            let evidence = adapter.extract(input: input)
            if adapter.adapterId == "unknown-fallback" {
                fallback = evidence
            } else {
                results.append(evidence)
            }
        }

        if let fallback {
            results.append(fallback)
        }
        return results
    }
}
