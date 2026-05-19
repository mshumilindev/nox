import Foundation

nonisolated enum NoxBehavioralHumilityLayer {

    static func softenEnrichmentNote(_ note: String) -> String {
        NoxReflectiveLanguageSoftener.soften(note)
    }

    static func softenResurfacingNote(_ note: String) -> String {
        var text = NoxReflectiveLanguageSoftener.soften(note)
        text = text.replacingOccurrences(of: "this month", with: "lately", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "You briefly returned", with: "There was a brief return", options: .caseInsensitive)
        return text
    }

    static func displaySignatures(
        _ signatures: [NoxBehavioralSignature],
        limit: Int = 1
    ) -> [NoxBehavioralSignatureDisplay] {
        NoxPatternConfidenceModel.gate(signatures, confidence: \.confidence, limit: limit)
            .map { sig in
                NoxBehavioralSignatureDisplay(
                    id: sig.id,
                    line: NoxReflectiveLanguageSoftener.soften(sig.detail),
                    subline: nil
                )
            }
    }

    static func softenDrift(_ drift: NoxBehavioralDriftInsight) -> NoxBehavioralDriftInsight {
        NoxBehavioralDriftInsight(
            label: NoxReflectiveLanguageSoftener.soften(drift.label),
            detail: NoxReflectiveLanguageSoftener.soften(drift.detail),
            confidence: drift.confidence,
            driftKind: drift.driftKind
        )
    }

    static func softenLifeStructure(_ structure: NoxLifeStructureCandidate) -> NoxLifeStructureCandidate {
        NoxLifeStructureCandidate(
            id: structure.id,
            label: NoxReflectiveLanguageSoftener.soften(structure.label),
            detail: NoxReflectiveLanguageSoftener.soften(structure.detail),
            confidence: structure.confidence,
            revisable: structure.revisable
        )
    }
}

nonisolated struct NoxBehavioralSignatureDisplay: Identifiable, Equatable, Sendable {
    let id: String
    let line: String
    let subline: String?
}
