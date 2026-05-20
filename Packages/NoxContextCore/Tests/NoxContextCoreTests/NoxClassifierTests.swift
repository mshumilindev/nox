import NoxContextCore
import NoxCore
import Testing

struct NoxClassifierPackageTests {

    @Test func classifiesXcodeAsDevelopment() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.apple.dt.Xcode",
            appName: "Xcode",
            windowTitle: "Nox — Xcode"
        )
        #expect(category == .development)
    }

    @Test func githubTitleRefinesSafari() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.apple.Safari",
            appName: "Safari",
            windowTitle: "GitHub - user/repo - Pull Request #442"
        )
        #expect(category == .development)
    }

    @Test func recognizesCommonNonLLMAppsCoarsely() {
        let classifier = NoxAppClassifier()

        #expect(classifier.classify(
            bundleId: "com.figma.Desktop",
            appName: "Figma",
            windowTitle: "Design system"
        ) == .creative)

        #expect(classifier.classify(
            bundleId: "com.microsoft.Word",
            appName: "Microsoft Word",
            windowTitle: "Proposal"
        ) == .productivity)

        #expect(classifier.classify(
            bundleId: "us.zoom.xos",
            appName: "zoom.us",
            windowTitle: "Team sync"
        ) == .communication)
    }

    @Test func classifiesChatGPTAsResearchNotUnknown() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.openai.chat",
            appName: "ChatGPT",
            windowTitle: "New chat"
        )
        #expect(category == .research)
        #expect(category.displayName != "Unknown")
    }

    @Test func resolvesLegacyUnknownCategoryFromAppIdentity() {
        let resolved = NoxActivityCategory.resolving(
            stored: .unknown,
            appName: "ChatGPT",
            bundleId: "com.openai.chat",
            windowTitle: nil
        )
        #expect(resolved == .research)
    }
}
