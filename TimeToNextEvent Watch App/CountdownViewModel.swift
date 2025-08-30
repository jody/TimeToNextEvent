//
//  CountdownViewModel.swift
//  TimeToNextEvent Watch App
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import Combine

final class CountdownViewModel: ObservableObject {

    enum State: Equatable {
        case requestingAccess
        case accessDenied
        case noUpcomingEvents
        case ready(eventTitle: String, startDate: Date, countdown: String)
        case error(message: String)
    }

    @Published private(set) var state: State = .requestingAccess

    private let eventProvider: EventProvider
    private var ticker: AnyCancellable?
    private var currentEvent: CalendarEvent?
    private var lastComputedMinute: Int?

    // Update cadence: once per second for snappy UI; we still format to minutes.
    private let tickInterval: TimeInterval = 1.0

    init(eventProvider: EventProvider) {
        self.eventProvider = eventProvider
    }

    func start() {
        Task { await self.bootstrap() }
        ticker = Timer
            .publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }

    private func bootstrap() async {
        do {
            let granted = try await eventProvider.requestAccess()
            if !granted {
                await MainActor.run { self.state = .accessDenied }
                return
            }
            await refreshEvent()
        } catch {
            await MainActor.run {
                self.state = .error(message: error.localizedDescription)
            }
        }
    }

    private func tick() {
        // To avoid recomputing every second, only recompute when the minute changes
        let minute = Calendar.current.component(.minute, from: Date())
        if minute != lastComputedMinute {
            lastComputedMinute = minute
            Task { await updateCountdownAndMaybeRefetch() }
        }
    }

    private func updateCountdownAndMaybeRefetch() async {
        guard let event = currentEvent else {
            await refreshEvent()
            return
        }
        let now = Date()
        if event.startDate <= now {
            // Event started; find the next one
            await refreshEvent()
            return
        }
        let countdown = Self.formatCountdown(from: now, to: event.startDate)
        await MainActor.run {
            self.state = .ready(eventTitle: event.title, startDate: event.startDate, countdown: countdown)
        }
    }

    private func refreshEvent() async {
        let now = Date()
        let next = await eventProvider.nextEvent(after: now)
        await MainActor.run {
            self.currentEvent = next
            if let e = next {
                let countdown = Self.formatCountdown(from: now, to: e.startDate)
                self.state = .ready(eventTitle: e.title, startDate: e.startDate, countdown: countdown)
            } else {
                self.state = .noUpcomingEvents
            }
        }
    }

    /// days, hours, minutes (no seconds) with zero padding for H/M
    static func formatCountdown(from: Date, to: Date) -> String {
        let comps = Calendar.current.dateComponents([.day, .hour, .minute], from: from, to: to)
        let d = max(comps.day ?? 0, 0)
        let h = max(comps.hour ?? 0, 0)
        let m = max(comps.minute ?? 0, 0)
        return "\(d)d \(String(format: "%02d", h))h \(String(format: "%02d", m))m"
    }
}
