import Foundation

extension Array where Element == String {
    nonisolated func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0.lowercased()).inserted }
    }
}
