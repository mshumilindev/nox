import SwiftUI

struct NoxObservatoryGraphLine: Identifiable {
    let id: String
    let title: String
    let description: String
    let color: Color
    let values: [NoxObservatoryPoint]

    static func collapsed(from series: [NoxObservatorySignalSeries]) -> [NoxObservatoryGraphLine] {
        NoxObservatorySignalGroup.allCases.compactMap { group in
            let groupSeries = series.filter { group.signals.contains($0.signal) && $0.isVisible }
            guard let first = groupSeries.first, !first.values.isEmpty else { return nil }
            let values = first.values.indices.map { index in
                let samples = groupSeries.compactMap { item -> Double? in
                    guard item.values.indices.contains(index) else { return nil }
                    return item.values[index].value
                }
                let value = samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
                return NoxObservatoryPoint(
                    id: "\(group.id)-\(index)",
                    timestamp: first.values[index].timestamp,
                    value: value
                )
            }
            return NoxObservatoryGraphLine(
                id: group.id,
                title: group.title,
                description: group.description,
                color: group.color,
                values: values
            )
        }
    }
}
