@testable import PersonalHygiene
import XCTest

@MainActor
final class TripCountdownTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func makeTrip(name: String, daysFromBase: Int) -> Trip {
        Trip(
            name: name,
            startDate: date(daysFromBase),
            endDate: date(daysFromBase + 5),
            destinationName: "X"
        )
    }

    func test_nextSummary_nilForEmpty() {
        XCTAssertNil(TripCountdown.nextSummary(
            trips: [],
            now: date(0),
            calendar: calendar()
        ))
    }

    func test_nextSummary_returnsClosestUpcoming() {
        let later = makeTrip(name: "Far", daysFromBase: 90)
        let sooner = makeTrip(name: "Close", daysFromBase: 14)
        let summary = TripCountdown.nextSummary(
            trips: [later, sooner],
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(summary?.tripName, "Close")
        XCTAssertEqual(summary?.daysUntil, 14)
    }

    func test_nextSummary_skipsAlreadyStarted() {
        let started = makeTrip(name: "Already", daysFromBase: -1)
        let upcoming = makeTrip(name: "Future", daysFromBase: 7)
        let summary = TripCountdown.nextSummary(
            trips: [started, upcoming],
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(summary?.tripName, "Future")
    }
}
