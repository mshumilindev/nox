import Foundation

/// Content and event classes that must never become long-term behavioral memory.
enum NoxForbiddenMemoryContent {
    static let forbiddenEventTypes: Set<String> = [
        NoxEventType.typingStarted.rawValue,
        NoxEventType.typingBurst.rawValue,
        NoxEventType.scrollActivity.rawValue,
        NoxEventType.mouseActivity.rawValue,
        NoxEventType.interactionIdle.rawValue,
        NoxEventType.interactionActive.rawValue
    ]

    static let forbiddenPersistenceFields: Set<String> = [
        "typed_text",
        "clipboard",
        "screenshot",
        "ocr",
        "accessibility_tree",
        "page_content",
        "password"
    ]

    static func mustNotPersistToWarmTimeline(eventType: NoxEventType) -> Bool {
        forbiddenEventTypes.contains(eventType.rawValue)
    }

    static func mustNotPersistToColdMemory(fieldName: String) -> Bool {
        forbiddenPersistenceFields.contains(fieldName.lowercased())
    }
}
