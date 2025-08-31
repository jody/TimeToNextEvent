//
//  NextEventWidget.swift
//  TimetoNextEventWidgetsExtension
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import WidgetKit
import SwiftUI

// Timeline entry for the complication
struct NextEventEntry: TimelineEntry {
    let date: Date
    let title: String
    let startDate: Date?     // nil => no upcoming event
}

// Provider: pulls from the shared snapshot written by the app
struct NextEventProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEventEntry {
        .init(date: Date(), title: "Next Event", startDate: Date().addingTimeInterval(3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (NextEventEntry) -> Void) {
        if let snap = SnapshotStore.read() {
            completion(.init(date: Date(), title: snap.title, startDate: snap.startDate))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEventEntry>) -> Void) {
        let now = Date()
        if let snap = SnapshotStore.read() {
            let entry = NextEventEntry(date: now, title: snap.title, startDate: snap.startDate)
            let halfHourFromNow = now.addingTimeInterval(30 * 60)
            let desired = min(halfHourFromNow, snap.startDate)
            let refreshAt = max(now.addingTimeInterval(60), desired)
            completion(Timeline(entries: [entry], policy: .after(refreshAt)))
        } else {
            let entry = NextEventEntry(date: now, title: "No Upcoming Events", startDate: nil)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60 * 60))))
        }
    }
}

// View rendering for different complication families
struct NextEventWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: NextEventEntry

    @ViewBuilder
    var body: some View {
        if let start = entry.startDate {
            switch family {
            case .accessoryInline:
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(start, style: .timer).monospacedDigit()
                }
            case .accessoryCircular:
                ZStack {
                    Text(start, style: .timer)
                        .minimumScaleFactor(0.6)
                        .monospacedDigit()
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title).font(.footnote).lineLimit(1)
                    Text(start, style: .timer).font(.title3).monospacedDigit()
                }
            case .accessoryCorner:
                Text(start, style: .timer).monospacedDigit()
            default:
                Text(start, style: .timer).monospacedDigit()
            }
        } else {
            switch family {
            case .accessoryInline:
                Label("No event", systemImage: "calendar.badge.exclamationmark")
            case .accessoryCircular:
                Image(systemName: "calendar.badge.exclamationmark")
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Upcoming Events").font(.footnote)
                    Text("--:--").font(.title3).monospacedDigit()
                }
            case .accessoryCorner:
                Image(systemName: "calendar.badge.exclamationmark")
            default:
                Text("No Upcoming Events")
            }
        }
    }
}

@main
struct NextEventWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextEventWidget",
                            provider: NextEventProvider()) { entry in
            NextEventWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows a live countdown to your next calendar event.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}
