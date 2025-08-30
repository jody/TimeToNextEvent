//
//  EventKitProvider.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import EventKit

final class EventKitEventProvider: EventProvider {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            store.requestFullAccessToEvents { granted, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: granted)
            }
        }
    }

    func nextEvent(after date: Date) async -> CalendarEvent? {
        // Search a window into the future (e.g., 14 days). Adjust if you prefer.
        let start = date
        let end = Calendar.current.date(byAdding: .day, value: 14, to: date) ?? date.addingTimeInterval(14 * 24 * 3600)

        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)

        // EventKit calls should be on a background queue to keep UI snappy.
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let events = self.store.events(matching: predicate)
                    .filter { $0.startDate > date } // strictly after "now"
                    .sorted(by: { $0.startDate < $1.startDate })

                if let e = events.first {
                    cont.resume(returning: CalendarEvent(title: e.title, startDate: e.startDate))
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}
