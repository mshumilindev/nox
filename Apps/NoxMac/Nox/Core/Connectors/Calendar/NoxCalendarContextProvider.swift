import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore
import EventKit

enum NoxCalendarContextProvider {

    static func accessState() -> NoxCalendarAccessState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess, .writeOnly:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    static func requestAccessIfNeeded() async -> NoxCalendarAccessState {
        let store = EKEventStore()
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        return granted ? .authorized : .denied
    }

    static func dayProfile(for date: Date = Date()) -> NoxCalendarDayProfile {
        guard accessState() == .authorized else { return .empty }
        let store = EKEventStore()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return .empty }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        guard !events.isEmpty else { return .empty }

        var meetingMinutes = 0
        var afternoonCount = 0
        var eveningCount = 0
        var backToBack = 0
        var gaps: [Int] = []
        var locationHints = 0

        for (index, event) in events.enumerated() {
            let duration = max(0, Int(event.endDate.timeIntervalSince(event.startDate) / 60))
            meetingMinutes += duration
            let hour = calendar.component(.hour, from: event.startDate)
            if hour >= 12 && hour < 17 { afternoonCount += 1 }
            if hour >= 18 { eveningCount += 1 }
            if let location = event.location, !location.isEmpty { locationHints += 1 }

            if index > 0 {
                let previous = events[index - 1]
                let gapMinutes = max(0, Int(event.startDate.timeIntervalSince(previous.endDate) / 60))
                gaps.append(gapMinutes)
                if gapMinutes <= 10 { backToBack += 1 }
            }
        }

        let longestGap = gaps.max() ?? 0
        let travelLike = locationHints >= 2 && events.count >= 3 && longestGap >= 90

        return NoxCalendarDayProfile(
            eventCount: events.count,
            meetingMinutes: meetingMinutes,
            longestGapMinutes: longestGap,
            afternoonEventCount: afternoonCount,
            eveningEventCount: eveningCount,
            backToBackBlocks: backToBack,
            hasTravelLikeStructure: travelLike
        )
    }
}
