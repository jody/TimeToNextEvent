//
//  EventProvider.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation

struct CalendarEvent: Equatable {
    let title: String
    let startDate: Date
    /// Optional calendar identifier (handy for filtering or tests)
    let calendarIdentifier: String?
}

protocol EventProvider {
    /// Returns true if access is granted.
    func requestAccess() async throws -> Bool

    /// Returns the very next event strictly after `date`.
    /// - Parameters:
    ///   - allowedCalendarIDs: when non-empty, only search these calendars.
    ///   - searchWindowDays: how many days ahead to search (min 1).
    func nextEvent(
        after date: Date,
        allowedCalendarIDs: Set<String>?,
        searchWindowDays: Int
    ) async -> CalendarEvent?
}
