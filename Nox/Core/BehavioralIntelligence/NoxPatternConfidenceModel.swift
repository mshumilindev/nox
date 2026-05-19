import Foundation

nonisolated enum NoxPatternConfidenceModel {
    static let minimumDisplay: Double = 0.55
    static let minimumPersist: Double = 0.58
    static let minimumStructure: Double = 0.52

    static func gate<T>(_ items: [T], confidence: (T) -> Double, limit: Int = 6) -> [T] {
        items
            .filter { confidence($0) >= minimumDisplay }
            .sorted { confidence($0) > confidence($1) }
            .prefix(limit)
            .map { $0 }
    }
}
