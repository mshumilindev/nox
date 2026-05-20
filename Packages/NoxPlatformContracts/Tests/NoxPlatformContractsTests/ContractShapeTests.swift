import Foundation
import Testing
@testable import NoxPlatformContracts

struct ContractShapeTests {
    @Test func activityObserverProtocolIsSendable() {
        struct Box: NoxActivityObserving {
            typealias Snapshot = Int
            typealias Event = String
            func activitySnapshots() -> AsyncStream<Int> { .init { $0.finish() } }
            func events() -> AsyncStream<String> { .init { $0.finish() } }
        }
        let _: any NoxActivityObserving = Box()
    }
}
