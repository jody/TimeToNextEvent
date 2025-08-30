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
    @State private var calendars: [EKCalendar] = []
    @State private var loading = true
    @State private var accessDenied = false

    private let store = EKEventStore()

    var body: some View {
        List {
            Section("Calendars") {
                if loading {
                    HStack {
                        ProgressView()
                        Text("Loading…")
                    }
                } else if accessDenied {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendar access is off.")
                            .font(.headline)
                        Text("Open the app’s permissions in Settings to choose calendars.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if calendars.isEmpty {
                    Text("No calendars found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(calendars, id: \.calendarIdentifier) { cal in
                        Toggle(isOn: Binding<Bool>(
                            get: { settings.selectedCalendarIDs.isEmpty ? true : settings.selectedCalendarIDs.contains(cal.calendarIdentifier) },
                            set: { newVal in
                                var ids = settings.selectedCalendarIDs
                                if newVal {
                                    ids.insert(cal.calendarIdentifier)
                                } else {
                                    ids.remove(cal.calendarIdentifier)
                                }
                                // Special handling: when user turns ALL off, treat as "all calendars" by storing empty set?
                                // UX: we’ll prevent "all off" by leaving at least one on.
                                if ids.isEmpty {
                                    // Keep at least one selected: re-add the toggled-off one to avoid "none"
                                    ids.insert(cal.calendarIdentifier)
                                }
                                settings.selectedCalendarIDs = ids
                            }
                        )) {
                            HStack {
                                Circle()
                                    .fill(Color(cal.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(cal.title)
                            }
                        }
                    }
                    Text("At least one calendar must stay selected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Look-ahead window") {
                Stepper(
                    value: $settings.searchWindowDays,
                    in: 1...60
                ) {
                    Text("\(settings.searchWindowDays) \(settings.searchWindowDays == 1 ? "day" : "days")")
                }
                Text("How far ahead to search for your next event.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("Changes take effect immediately.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task { await loadCalendars() }
    }

    private func loadCalendars() async {
        loading = true
        defer { loading = false }
        do {
            // If not granted yet, request; on watch this shows in-app prompt.
            let granted: Bool = try await withCheckedThrowingContinuation { cont in
                store.requestFullAccessToEvents { ok, err in
                    if let err { cont.resume(throwing: err) }
                    else { cont.resume(returning: ok) }
                }
            }
            if !granted {
                accessDenied = true
                return
            }
            let cals = store.calendars(for: .event)
            await MainActor.run { calendars = cals.sorted(by: { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) }
        } catch {
            accessDenied = true
        }
    }
}

private extension Color {
    init(_ cgColor: CGColor?) {
        if let cgColor { self = Color(cgColor) }
        else { self = .accentColor }
    }
}

#Preview {
    SettingsView(settings: SettingsStore())
}
