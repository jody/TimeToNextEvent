//
//  SettingsStore.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import Combine

/// User preferences backing store. Keep simple for watch-only.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var selectedCalendarIDs: Set<String> {
        didSet { saveSelectedCalendarIDs() }
    }

    /// Search look-ahead window in days (1...60). Default 14.
    @Published var searchWindowDays: Int {
        didSet {
            if searchWindowDays < 1 { searchWindowDays = 1 }
            if searchWindowDays > 60 { searchWindowDays = 60 }
            UserDefaults.standard.set(searchWindowDays, forKey: Keys.searchDays)
        }
    }

    private enum Keys {
        static let selectedCalendarIDs = "ttne.selectedCalendarIDs.v1"
        static let searchDays = "ttne.searchDays.v1"
    }

    init() {
        // Load calendars
        if let data = UserDefaults.standard.data(forKey: Keys.selectedCalendarIDs),
           let set = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.selectedCalendarIDs = set
        } else {
            self.selectedCalendarIDs = [] // default: all calendars
        }
        // Load days
        let days = UserDefaults.standard.integer(forKey: Keys.searchDays)
        self.searchWindowDays = (days == 0) ? 14 : days
    }

    private func saveSelectedCalendarIDs() {
        if let data = try? JSONEncoder().encode(selectedCalendarIDs) {
            UserDefaults.standard.set(data, forKey: Keys.selectedCalendarIDs)
        }
    }
}
