//
//  CountdownViewModelTests.swift
//  TimeToNextEvent Watch AppTests
//
//  Created by Jody Paul on 8/30/25.
//

import Foundation
import XCTest
@testable import TimeToNextEvent_Watch_App

final class CountdownViewModelTests: XCTestCase {

    func testFormatCountdown_RoundsDownToWholeMinutes() {
        // from: 0s, to: 1d 2h 3m 59s → 1d 02h 03m (we ignore seconds)
        let cal = Calendar.current
        let from = Date()
        let to = cal.date(byAdding: DateComponents(day: 1, hour: 2, minute: 3, second: 59), to: from)!
        let s = CountdownViewModel.formatCountdown(from: from, to: to)
        XCTAssertEqual(s, "1d 02h 03m")
    }

    func testNextEventFlow_NoAccess() async {
        let mock = MockEventProvider()
        mock.granted = false
        let vm = CountdownViewModel(eventProvider: mock)

        let exp = expectation(description: "state becomes accessDenied")
        let cancel = vm.$state.dropFirst().sink { state in
            if case .accessDenied = state { exp.fulfill() }
        }

        vm.start()
        defer { vm.stop(); cancel.cancel() }
        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testNextEventFlow_Ready() async {
        let mock = MockEventProvider()
        mock.granted = true
        let soon = Date().addingTimeInterval(3600 * 6 + 60 * 4) // 6h 4m
        mock.events = [CalendarEvent(title: "Faculty Meeting", startDate: soon)]
        let vm = CountdownViewModel(eventProvider: mock)

        let exp = expectation(description: "state becomes ready")
        let cancel = vm.$state.dropFirst().sink { state in
            if case .ready(let title, let start, let countdown) = state {
                XCTAssertEqual(title, "Faculty Meeting")
                XCTAssertEqual(start.timeIntervalSince1970, soon.timeIntervalSince1970, accuracy: 1)
                XCTAssertTrue(countdown.contains("06h"))
                exp.fulfill()
            }
        }

        vm.start()
        defer { vm.stop(); cancel.cancel() }
        await fulfillment(of: [exp], timeout: 2.0)
    }

    // Helper for async expectations in Swift 5.9+
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            XCTWaiter().wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
}
