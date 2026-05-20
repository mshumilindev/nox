import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxInterruption: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let fromApp: String
    public let fromBundleId: String
    public let toApp: String
    public let toBundleId: String
    public let durationMs: Int
    public let returnedBack: Bool

    public init(
        id: String,
        timestamp: Date,
        fromApp: String,
        fromBundleId: String,
        toApp: String,
        toBundleId: String,
        durationMs: Int,
        returnedBack: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fromApp = fromApp
        self.fromBundleId = fromBundleId
        self.toApp = toApp
        self.toBundleId = toBundleId
        self.durationMs = durationMs
        self.returnedBack = returnedBack
    }
}
