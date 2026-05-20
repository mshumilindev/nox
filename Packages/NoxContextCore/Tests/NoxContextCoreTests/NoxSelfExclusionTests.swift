import NoxContextCore
import NoxCore
import Testing

struct NoxSelfExclusionCategoryPackageTests {

    @Test func excludesOwnBundleId() {
        let previous = NoxSelfExclusion.ownBundleId
        defer { NoxSelfExclusion.ownBundleId = previous }
        NoxSelfExclusion.ownBundleId = "dev.nox.Nox"
        #expect(NoxSelfExclusion.isExcluded(bundleId: "dev.nox.Nox"))
    }

    @Test func excludesAppNameNox() {
        #expect(NoxSelfExclusion.isExcluded(bundleId: "com.other.app", appName: "Nox"))
    }

    @Test func doesNotExcludeOtherApps() {
        #expect(!NoxSelfExclusion.isExcluded(bundleId: "com.apple.Safari", appName: "Safari"))
    }

    @Test func noxMapsToSystemInternalCategory() {
        #expect(NoxSelfExclusion.analysisCategory == .systemInternal)
        #expect(NoxAppClassifier().classify(
            bundleId: NoxSelfExclusion.ownBundleId ?? "dev.nox.Nox",
            appName: "Nox",
            windowTitle: nil
        ) == .systemInternal)
    }

    @Test func systemInternalExcludedFromAnalysis() {
        #expect(NoxActivityCategory.systemInternal.excludedFromAnalysis)
        #expect(!NoxActivityCategory.development.excludedFromAnalysis)
    }
}
