//
//  SettingsView.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import SwiftUI
import EventKit

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let eventProvider: EventProvider

    @State private var calendars: [CalendarInfo] = []
    @State private var isLoading = true
    @State private var accessDenied = false

    var body: some View {
        List {
            // CALENDARS — always visible
            Section {
                NavigationLink {
                    CalendarChooserView(
                        calendars: calendars,
                        selection: $settings.selectedCalendarIDs
                    )
                    .navigationTitle("Calendars")
                    .task { await reloadCalendars() } // pull again on push just in case
                } label: {
                    HStack {
                        Text("Calendars")
                        Spacer()
                        Text(calendarsSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                if accessDenied {
                    Text("Access denied. Allow Calendar access for this app on your Apple Watch.")
                } else if calendars.isEmpty && !isLoading {
                    Text("No calendars found. This is common on the simulator; try on a real watch.")
                }
            }

            // LOOK-AHEAD
            Section("Look-ahead") {
                Picker("Days", selection: $settings.searchWindowDays) {
                    ForEach([1,3,7,14,30,60,90], id: \.self) { d in
                        Text("\(d) day\(d == 1 ? "" : "s")").tag(d)
                    }
                }
                .pickerStyle(.navigationLink)

                Text("We’ll look ahead this many days to find your next event.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task { await initialLoad() }
    }

    private var calendarsSummary: String {
        if accessDenied { return "Access denied" }
        if isLoading { return "Loading…" }
        if calendars.isEmpty { return "None" }
        if settings.selectedCalendarIDs.isEmpty { return "All" }
        let sel = calendars.filter { settings.selectedCalendarIDs.contains($0.id) }.count
        return "\(sel) of \(calendars.count)"
    }

    @MainActor
    private func initialLoad() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let granted = try await eventProvider.requestAccess()
            accessDenied = !granted
        } catch {
            accessDenied = true
        }
        calendars = await eventProvider.listCalendars()
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    @MainActor
    private func reloadCalendars() async {
        calendars = await eventProvider.listCalendars()
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

#Preview {
    SettingsView(settings: SettingsStore.shared, eventProvider: MockEventProvider())
}
