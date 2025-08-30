//
//  TimeToNextEventApp.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import SwiftUI

@main
struct TimeToNextEventApp: App {
    @StateObject private var settings = SettingsStore()
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: CountdownViewModel(
                    eventProvider: EventKitEventProvider(),
                    settings: settings
                )
            )
            .environmentObject(settings) // Make settings available to the UI.
        }
    }
}
