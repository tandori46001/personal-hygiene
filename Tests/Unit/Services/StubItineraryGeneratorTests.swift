import XCTest

@testable import PersonalHygiene

final class StubItineraryGeneratorTests: XCTestCase {

    private func date(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return DateComponents(calendar: cal, timeZone: cal.timeZone, year: year, month: month, day: day).date!
    }

    @MainActor
    func test_generate_returnsOneDayPerCalendarDay() async throws {
        let trip = Trip(
            name: "Mediterráneo",
            startDate: date(year: 2026, month: 6, day: 1),
            endDate: date(year: 2026, month: 6, day: 4),
            destinationName: "Mallorca"
        )
        let result = try await StubItineraryGenerator().generate(for: trip)
        XCTAssertEqual(result.days.count, 3)
    }

    @MainActor
    func test_generate_includesDestinationInSummary() async throws {
        let trip = Trip(
            name: "Solo trip",
            startDate: date(year: 2026, month: 6, day: 1),
            endDate: date(year: 2026, month: 6, day: 2),
            destinationName: "Lisbon"
        )
        let result = try await StubItineraryGenerator().generate(for: trip)
        XCTAssertTrue(result.summary.contains("Lisbon"))
    }

    @MainActor
    func test_generate_clampsToAtLeastOneDay() async throws {
        let trip = Trip(
            name: "Same-day",
            startDate: date(year: 2026, month: 6, day: 1),
            endDate: date(year: 2026, month: 6, day: 1),
            destinationName: "Madrid"
        )
        let result = try await StubItineraryGenerator().generate(for: trip)
        XCTAssertEqual(result.days.count, 1)
    }
}
