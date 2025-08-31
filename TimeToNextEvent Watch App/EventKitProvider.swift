//
//  EventKitProvider.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import EventKit

@MainActor
final class EventKitEventProvider: EventProvider {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            // Completion can arrive on any queue; we're on the main actor at call site.
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: granted)
                }
            }
        }
    }

    func listCalendars() async -> [CalendarInfo] {
        store.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title)
        }
    }

    func nextEvent(
        after date: Date,
        allowedCalendarIDs: Set<String>?,
        searchWindowDays: Int
    ) async -> CalendarEvent? {
        let days = max(searchWindowDays, 1)
        let start = date
        let end = Calendar.current.date(byAdding: .day, value: days, to: date)
            ?? date.addingTimeInterval(TimeInterval(days) * 24 * 3600)

        var calendars = store.calendars(for: .event)
        if let allowed = allowedCalendarIDs, !allowed.isEmpty {
            let allowedSet = Set(allowed)
            calendars = calendars.filter { allowedSet.contains($0.calendarIdentifier) }
        }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)

        // Lightweight query on the main actor (no @Sendable capture problems).
        let events = store.events(matching: predicate)
            .filter { $0.startDate > date }
            .sorted { $0.startDate < $1.startDate }

        if let e = events.first {
            return CalendarEvent(
                title: e.title,
                startDate: e.startDate,
                calendarIdentifier: e.calendar.calendarIdentifier
            )
        }
        return nil
    }
}
