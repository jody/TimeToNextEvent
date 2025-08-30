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
}

protocol EventProvider {
    /// Returns true if access is granted.
    func requestAccess() async throws -> Bool
    /// Returns the very next event strictly after `date` across all calendars, or nil if none.
    func nextEvent(after date: Date) async -> CalendarEvent?
}
