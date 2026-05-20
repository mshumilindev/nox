import Foundation
import NoxCore

public protocol NoxContextAdapter: Sendable {
    var adapterId: String { get }
    var reliability: Double { get }
    /// Higher runs first; generic adapter should be lowest.
    var priority: Int { get }
    func matches(input: NoxContextAdapterInput) -> Bool
    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence
}
