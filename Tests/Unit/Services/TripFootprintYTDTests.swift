@testable import PersonalHygiene
@preconcurrency import XCTest

final class TripFootprintYTDTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: calendar(), timeZone: TimeZone(secondsFromGMT: 0),
            year: year, month: month, day: day
        ).date!
    }

    func test_summarize_sumsContributionsInCurrentYear() {
        let now = date(year: 2026, month: 4, day: 28)
        let contributions: [(startDate: Date, kgCO2: Double)] = [
            (date(year: 2026, month: 1, day: 5), 100),
            (date(year: 2026, month: 3, day: 12), 50),
            (date(year: 2025, month: 12, day: 30), 999),  // last year — excluded
        ]
        let summary = TripFootprintYTD.summarize(
            contributions: contributions,
            now: now,
            calendar: calendar()
        )
        XCTAssertEqual(summary.totalKgCO2, 150)
        XCTAssertEqual(summary.tripCount, 2)
    }

    func test_summarize_emptyForNoContributions() {
        let summary = TripFootprintYTD.summarize(
            contributions: [],
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar()
        )
        XCTAssertEqual(summary.totalKgCO2, 0)
        XCTAssertEqual(summary.tripCount, 0)
    }
}
