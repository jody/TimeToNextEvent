//
//  CalendarChooserView.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import SwiftUI

struct CalendarChooserView: View {
    let calendars: [CalendarInfo]
    @Binding var selection: Set<String>   // empty = All

    var body: some View {
        List {
            Section {
                Button {
                    selection = [] // empty means All
                } label: {
                    CalendarRow(title: "All Calendars", selected: selection.isEmpty)
                }
            }

            Section("Choose Calendars") {
                ForEach(calendars) { cal in
                    Button {
                        toggle(id: cal.id)
                    } label: {
                        CalendarRow(title: cal.title, selected: isSelected(cal.id))
                    }
                }
            }

            Section {
                Text("Tip: Leaving everything selected is the same as “All”.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calendars")
    }

    private func isSelected(_ id: String) -> Bool {
        // Empty set = All (treat as selected for display)
        selection.isEmpty || selection.contains(id)
    }

    private func toggle(id: String) {
        var set = selection
        if set.isEmpty {
            // Expand "All" into explicit full set before toggling one off
            set = Set(calendars.map { $0.id })
        }
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
        // If user ends up with all selected, collapse back to "All"
        if set.count == calendars.count { set = [] }
        selection = set
    }
}

// Small, compiler-friendly row view with a trailing checkmark
private struct CalendarRow: View {
    let title: String
    let selected: Bool

    var body: some View {
        HStack {
            Text(title).lineLimit(1)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)   // simple overload; fast to type-check
                    .imageScale(.medium)
            }
        }
    }
}
