//
//  SharedSnapshot.swift
//  TimetoNextEventWidgetsExtension
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit   // for reloadAllTimelines() after writes
#endif

enum AppGroup {
    static let id = "group.com.jodypaul.timetonextevent"
}

struct NextEventSnapshot: Codable {
    let title: String
    let startDate: Date
    let updatedAt: Date
}

enum SnapshotStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }
    private static let key = "nextEventSnapshot"

    static func write(_ snap: NextEventSnapshot) {
        let enc = JSONEncoder()
        if let data = try? enc.encode(snap) {
            defaults.set(data, forKey: key)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    static func read() -> NextEventSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(NextEventSnapshot.self, from: data)
    }

    static func clear() {
        defaults.removeObject(forKey: key)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
