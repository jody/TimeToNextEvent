//
//  MockEventProvider.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

#if DEBUG
import Foundation

final class MockEventProvider: EventProvider {
    var granted = true
    var events: [CalendarEvent] = []

    func requestAccess() async throws -> Bool { granted }

    func nextEvent(after date: Date) async -> CalendarEvent? {
        events.filter { $0.startDate > date }.sorted { $0.startDate < $1.startDate }.first
    }

    static var preview: MockEventProvider {
        let m = MockEventProvider()
        m.events = [
            CalendarEvent(title: "CS Dept Standup",
                          startDate: Date().addingTimeInterval(5*3600 + 12*60))
        ]
        return m
    }
}
#endif
