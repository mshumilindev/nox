import Foundation
import NoxSemanticCore
import NoxContinuityCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxObservatoryTimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case last24Hours
    case last7Days
    case last30Days
    case allTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: "Today"
        case .last24Hours: "24h"
        case .last7Days: "7d"
        case .last30Days: "30d"
        case .allTime: "All"
        }
    }

    public func dateRange(now: Date = Date(), earliest: Date? = nil, calendar: Calendar = .current) -> (start: Date, end: Date) {
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

public enum NoxObservatoryBucketSize: TimeInterval, Sendable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case twoHours = 7200
    case oneDay = 86400

    public var label: String {
        switch self {
        case .fifteenMinutes: "15m"
        case .thirtyMinutes: "30m"
        case .twoHours: "2h"
        case .oneDay: "1d"
        }
    }

    public static func fitting(duration: TimeInterval) -> NoxObservatoryBucketSize {
        if duration <= 24 * 3600 { return .fifteenMinutes }
        if duration <= 72 * 3600 { return .thirtyMinutes }
        if duration <= 14 * 24 * 3600 { return .twoHours }
        return .oneDay
    }
}

public enum NoxObservatoryMaturityLevel: Int, Comparable, Sendable {
    case gathering
    case weak
    case tentative
    case normal
    case longHorizon

    public static func < (lhs: NoxObservatoryMaturityLevel, rhs: NoxObservatoryMaturityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func from(observedSeconds: TimeInterval) -> NoxObservatoryMaturityLevel {
        let hours = observedSeconds / 3600
        if hours < 6 { return .gathering }
        if hours < 24 { return .weak }
        if hours < 72 { return .tentative }
        if hours < 168 { return .normal }
        return .longHorizon
    }

    public var copy: String {
        switch self {
        case .gathering: "Still collecting enough local activity for a clear read."
        case .weak: "Not enough signal yet — Nox is holding off on strong summaries."
        case .tentative: "Early trends are visible; summaries may still change."
        case .normal: "Recent activity supports steady summaries."
        case .longHorizon: "Longer-range trends are available."
        }
    }

    public var confidenceCeiling: Double {
        switch self {
        case .gathering: 0.25
        case .weak: 0.42
        case .tentative: 0.62
        case .normal: 0.82
        case .longHorizon: 1
        }
    }
}

public struct NoxObservatoryPoint: Identifiable, Equatable, Sendable {
    public let id: String
    public let timestamp: Date
    public let value: Double

    public init(id: String, timestamp: Date, value: Double) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}

public struct NoxObservatorySignalSeries: Identifiable, Equatable, Sendable {
    public let id: String
    public let signal: NoxObservatorySignal
    public let values: [NoxObservatoryPoint]
    public let confidence: Double
    public var isVisible: Bool
    public let observationWeight: Double

    public init(
        id: String,
        signal: NoxObservatorySignal,
        values: [NoxObservatoryPoint],
        confidence: Double,
        isVisible: Bool,
        observationWeight: Double
    ) {
        self.id = id
        self.signal = signal
        self.values = values
        self.confidence = confidence
        self.isVisible = isVisible
        self.observationWeight = observationWeight
    }

    public var title: String { signal.title }
    public var description: String { signal.description }
}

public enum NoxObservatoryObservationSeverity: Int, Sendable {
    case note
    case elevated
    case severe
}

public struct NoxObservatoryObservation: Identifiable, Equatable, Sendable {
    public let id: String
    public let severity: NoxObservatoryObservationSeverity
    public let title: String
    public let detail: String
    public let confidence: Double
    public let evidence: [String]
}

public struct NoxObservatorySnapshot: Equatable, Sendable {
    public let range: NoxObservatoryTimeRange
    public let bucketSize: NoxObservatoryBucketSize
    public let start: Date
    public let end: Date
    public let maturity: NoxObservatoryMaturityLevel
    public let observedSeconds: TimeInterval
    public let series: [NoxObservatorySignalSeries]
    public let observations: [NoxObservatoryObservation]
    public let generatedAt: Date

    public init(
        range: NoxObservatoryTimeRange,
        bucketSize: NoxObservatoryBucketSize,
        start: Date,
        end: Date,
        maturity: NoxObservatoryMaturityLevel,
        observedSeconds: TimeInterval,
        series: [NoxObservatorySignalSeries],
        observations: [NoxObservatoryObservation],
        generatedAt: Date
    ) {
        self.range = range
        self.bucketSize = bucketSize
        self.start = start
        self.end = end
        self.maturity = maturity
        self.observedSeconds = observedSeconds
        self.series = series
        self.observations = observations
        self.generatedAt = generatedAt
    }

    public static let empty = NoxObservatorySnapshot(
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
