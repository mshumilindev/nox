import NoxSemanticCore
import Testing

struct NoxSemanticConfidencePackageTests {

    @Test func qualifiersRespectThresholds() {
        #expect(NoxSemanticConfidence.qualifier(for: 0.3).isEmpty)
        #expect(NoxSemanticConfidence.qualifier(for: 0.5) == "Possibly")
        #expect(NoxSemanticConfidence.qualifier(for: 0.7) == "Likely")
    }
}
