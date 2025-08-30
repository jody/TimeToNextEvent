//
//  CountdownViewModelTests.swift
//  TimeToNextEvent Watch AppTests
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import XCTest
import Combine
@testable import TimeToNextEvent_Watch_App


final class CountdownViewModelTests: XCTestCase {
    private var bag = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        bag = []
    }

    override func tearDown() {
        bag.removeAll()
        super.tearDown()
    }

    func testFormatCountdown_RoundsDownToWholeMinutes() {
        let cal = Calendar.current
        let from = Date()
        let to = cal.date(byAdding: DateComponents(day: 1, hour: 2, minute: 3, second: 59), to: from)!
        let s = CountdownViewModel.formatCountdown(from: from, to: to)
        XCTAssertEqual(s, "1d 02h 03m")
    }

    func testNextEventFlow_NoAccess() async {
        #if DEBUG
        let mock = MockEventProvider(); mock.granted = false
        let settings = SettingsStore()
        let vm = CountdownViewModel(eventProvider: mock, settings: settings)

        let exp = expectation(description: "state becomes accessDenied")
        vm.$state.dropFirst().sink { state in
            if case .accessDenied = state { exp.fulfill() }
        }.store(in: &bag)

        vm.start()
        defer { vm.stop() }
        await fulfillment(of: [exp], timeout: 2.0)
        #endif
    }

    func testNextEventFlow_Ready_RespectsSettings() async {
        #if DEBUG
        let mock = MockEventProvider(); mock.granted = true
        let settings = SettingsStore()
        settings.selectedCalendarIDs = ["CAL-1"]
        settings.searchWindowDays = 2

        let now = Date()
        mock.events = [
            CalendarEvent(title: "Should Be Ignored (wrong cal)",
                          startDate: now.addingTimeInterval(3600),
                          calendarIdentifier: "CAL-2"),
            CalendarEvent(title: "Faculty Meeting",
                          startDate: now.addingTimeInterval(6*3600 + 4*60),
                          calendarIdentifier: "CAL-1")
        ]

        let vm = CountdownViewModel(eventProvider: mock, settings: settings)

        let exp = expectation(description: "state becomes ready")
        vm.$state.dropFirst().sink { state in
            if case .ready(let title, _, let countdown) = state {
                XCTAssertEqual(title, "Faculty Meeting")
                XCTAssertTrue(countdown.contains("06h"))
                exp.fulfill()
            }
        }.store(in: &bag)

        vm.start()
        defer { vm.stop() }
        await fulfillment(of: [exp], timeout: 2.0)

        // Verify settings passed through to provider
        XCTAssertEqual(mock.lastAllowedIDs, ["CAL-1"])
        XCTAssertEqual(mock.lastDays, 2)
        #endif
    }

    // Helper for async expectations in Swift 5.9+
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            XCTWaiter().wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}
