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
    private let settings: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    
    private var ticker: AnyCancellable?
    private var currentEvent: CalendarEvent?
    private var lastComputedMinute: Int?
    
    private let tickInterval: TimeInterval = 1.0
    
    init(eventProvider: EventProvider, settings: SettingsStore) {
        self.eventProvider = eventProvider
        self.settings = settings
        
        // Refresh when user changes calendars or window.
        settings.$selectedCalendarIDs
            .merge(with: settings.$searchWindowDays.map { _ in Set<String>() }) // trigger on either change
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in Task { await self?.refreshEvent() } }
            .store(in: &cancellables)
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
            await refreshEvent()
            return
        }
        let countdown = Self.formatCountdown(from: now, to: event.startDate)
        await MainActor.run {
            self.state = .ready(eventTitle: event.title, startDate: event.startDate, countdown: countdown)
            self.writeSnapshot(event)
        }
    }
    
    private func refreshEvent() async {
        let now = Date()
        let next = await eventProvider.nextEvent(
            after: now,
            allowedCalendarIDs: settings.selectedCalendarIDs.isEmpty ? nil : settings.selectedCalendarIDs,
            searchWindowDays: settings.searchWindowDays
        )
        await MainActor.run {
            self.currentEvent = next
            if let e = next {
                let countdown = Self.formatCountdown(from: now, to: e.startDate)
                self.state = .ready(eventTitle: e.title, startDate: e.startDate, countdown: countdown)
                self.writeSnapshot(e)
            } else {
                self.state = .noUpcomingEvents
            }
        }
    }
    
    static func formatCountdown(from: Date, to: Date) -> String {
        let comps = Calendar.current.dateComponents([.day, .hour, .minute], from: from, to: to)
        let d = max(comps.day ?? 0, 0)
        let h = max(comps.hour ?? 0, 0)
        let m = max(comps.minute ?? 0, 0)
        return "\(d)d \(String(format: "%02d", h))h \(String(format: "%02d", m))m"
    }

    private func writeSnapshot(_ event: CalendarEvent) {
        let snap = NextEventSnapshot(title: event.title, startDate: event.startDate, updatedAt: Date())
        SnapshotStore.write(snap)
    }

}
