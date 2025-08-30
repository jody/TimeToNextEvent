//
//  ContentView.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: CountdownViewModel

    var body: some View {
        VStack(spacing: 10) {
            switch viewModel.state {
            case .requestingAccess:
                ProgressView()
                    .tint(.accentColor)
                Text("Requesting Calendar Access…")
                    .font(.footnote)
                    .multilineTextAlignment(.center)

            case .accessDenied:
                Image(systemName: "lock.slash")
                    .font(.largeTitle)
                Text("Calendar Access Needed")
                    .font(.headline)
                Text("Open Settings on your Apple Watch and allow Calendar access for this app.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

            case .noUpcomingEvents:
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.largeTitle)
                Text("No Upcoming Events")
                    .font(.headline)
                Text("We’ll keep checking and update automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case .ready(let eventTitle, let startDate, let countdown):
                VStack(spacing: 6) {
                    Text(countdown)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .monospacedDigit()

                    Text(eventTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(startDate, style: .time)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            case .error(let message):
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("Something went wrong")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

#Preview {
    ContentView(viewModel: CountdownViewModel(eventProvider: MockEventProvider.preview))
}
