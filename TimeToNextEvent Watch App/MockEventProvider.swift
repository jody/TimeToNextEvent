//
//  MockEventProvider.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

//#if DEBUG
import Foundation

final class MockEventProvider: EventProvider {
    var granted = true
    var events: [CalendarEvent] = []

    // For testing we capture the last parameters passed in:
    private(set) var lastAllowedIDs: Set<String>?
    private(set) var lastDays: Int = 0

    func requestAccess() async throws -> Bool { granted }

    var calendars: [CalendarInfo] = [
        CalendarInfo(id: "A", title: "Personal"),
        CalendarInfo(id: "B", title: "Work")
    ]

    func listCalendars() async -> [CalendarInfo] { calendars }

    func nextEvent(
        after date: Date,
        allowedCalendarIDs: Set<String>?,
        searchWindowDays: Int
    ) async -> CalendarEvent? {
        lastAllowedIDs = allowedCalendarIDs
        lastDays = searchWindowDays

        let filtered: [CalendarEvent]
        if let ids = allowedCalendarIDs, !ids.isEmpty {
            filtered = events.filter { ev in
                guard let cid = ev.calendarIdentifier else { return false }
                return ids.contains(cid)
            }
        } else {
            filtered = events
        }

        let end = date.addingTimeInterval(TimeInterval(max(searchWindowDays, 1)) * 24 * 3600)
        return filtered
            .filter { $0.startDate > date && $0.startDate <= end }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    // SwiftUI preview convenience
    static var preview: MockEventProvider {
        let m = MockEventProvider()
        m.events = [
            CalendarEvent(title: "Dummy Meeting",
                          startDate: Date().addingTimeInterval(5*3600 + 12*60),
                          calendarIdentifier: "CAL-A")
        ]
        return m
    }
}
//#endif
