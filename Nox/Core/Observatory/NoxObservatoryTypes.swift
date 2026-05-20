import Foundation
import SwiftUI

nonisolated enum NoxObservatoryTimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case last24Hours
    case last7Days
    case last30Days
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .last24Hours: "24h"
        case .last7Days: "7d"
        case .last30Days: "30d"
        case .allTime: "All"
        }
    }

    func dateRange(now: Date = Date(), earliest: Date? = nil, calendar: Calendar = .current) -> (start: Date, end: Date) {
        switch self {
        case .today:
            return (calendar.startOfDay(for: now), now)
        case .last24Hours:
            return (now.addingTimeInterval(-24 * 3600), now)
        case .last7Days:
            return (now.addingTimeInterval(-7 * 24 * 3600), now)
        case .last30Days:
            return (now.addingTimeInterval(-30 * 24 * 3600), now)
        case .allTime:
            return (earliest ?? now.addingTimeInterval(-24 * 3600), now)
        }
    }
}

nonisolated enum NoxObservatoryBucketSize: TimeInterval, Sendable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case twoHours = 7200
    case oneDay = 86400

    var label: String {
        switch self {
        case .fifteenMinutes: "15m"
        case .thirtyMinutes: "30m"
        case .twoHours: "2h"
        case .oneDay: "1d"
        }
    }

    static func fitting(duration: TimeInterval) -> NoxObservatoryBucketSize {
        if duration <= 24 * 3600 { return .fifteenMinutes }
        if duration <= 72 * 3600 { return .thirtyMinutes }
        if duration <= 14 * 24 * 3600 { return .twoHours }
        return .oneDay
    }
}

nonisolated enum NoxObservatoryMaturityLevel: Int, Comparable, Sendable {
    case gathering
    case weak
    case tentative
    case normal
    case longHorizon

    static func < (lhs: NoxObservatoryMaturityLevel, rhs: NoxObservatoryMaturityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(observedSeconds: TimeInterval) -> NoxObservatoryMaturityLevel {
        let hours = observedSeconds / 3600
        if hours < 6 { return .gathering }
        if hours < 24 { return .weak }
        if hours < 72 { return .tentative }
        if hours < 168 { return .normal }
        return .longHorizon
    }

    var copy: String {
        switch self {
        case .gathering: "Observatory is still gathering continuity."
        case .weak: "Signal confidence is weak. Hard conclusions are withheld."
        case .tentative: "Tentative trends are visible, but still provisional."
        case .normal: "Continuity interpretation is active."
        case .longHorizon: "Long-horizon observations are enabled."
        }
    }

    var confidenceCeiling: Double {
        switch self {
        case .gathering: 0.25
        case .weak: 0.42
        case .tentative: 0.62
        case .normal: 0.82
        case .longHorizon: 1
        }
    }
}

nonisolated struct NoxObservatoryPoint: Identifiable, Equatable, Sendable {
    let id: String
    let timestamp: Date
    let value: Double
}

nonisolated struct NoxObservatorySignalSeries: Identifiable, Equatable, Sendable {
    let id: String
    let signal: NoxObservatorySignal
    let values: [NoxObservatoryPoint]
    let confidence: Double
    var isVisible: Bool
    let observationWeight: Double

    var title: String { signal.title }
    var description: String { signal.description }
}

nonisolated enum NoxObservatoryObservationSeverity: Int, Sendable {
    case note
    case elevated
    case severe
}

nonisolated struct NoxObservatoryObservation: Identifiable, Equatable, Sendable {
    let id: String
    let severity: NoxObservatoryObservationSeverity
    let title: String
    let detail: String
    let confidence: Double
    let evidence: [String]
}

nonisolated struct NoxObservatorySnapshot: Equatable, Sendable {
    let range: NoxObservatoryTimeRange
    let bucketSize: NoxObservatoryBucketSize
    let start: Date
    let end: Date
    let maturity: NoxObservatoryMaturityLevel
    let observedSeconds: TimeInterval
    let series: [NoxObservatorySignalSeries]
    let observations: [NoxObservatoryObservation]
    let generatedAt: Date

    static let empty = NoxObservatorySnapshot(
        range: .last24Hours,
        bucketSize: .fifteenMinutes,
        start: Date().addingTimeInterval(-24 * 3600),
        end: Date(),
        maturity: .gathering,
        observedSeconds: 0,
        series: NoxObservatorySignal.allCases.map {
            NoxObservatorySignalSeries(
                id: $0.id,
                signal: $0,
                values: [],
                confidence: 0,
                isVisible: true,
                observationWeight: 0
            )
        },
        observations: [],
        generatedAt: .distantPast
    )
}
