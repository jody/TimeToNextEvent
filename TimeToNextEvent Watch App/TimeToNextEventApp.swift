//
//  TimeToNextEventApp.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import SwiftUI

@main
struct TimeToNextEventApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: CountdownViewModel(
                    eventProvider: EventKitEventProvider()
                )
            )
        }
    }
}
