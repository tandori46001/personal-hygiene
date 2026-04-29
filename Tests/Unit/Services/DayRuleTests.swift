import XCTest

@testable import PersonalHygiene

final class DayRuleTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps)!
    }

    // MARK: - fixedMonthDay

    func test_fixedMonthDay_resolves_correctly() {
        let xmas = DayRule.fixedMonthDay(month: 12, day: 25)
        XCTAssertEqual(xmas.resolvedDate(in: 2026, calendar: calendar), date(2026, 12, 25))
    }

    func test_fixedMonthDay_matches_anyYearWithSameMonthDay() {
        let xmas = DayRule.fixedMonthDay(month: 12, day: 25)
        XCTAssertTrue(xmas.matches(date(2026, 12, 25), calendar: calendar))
        XCTAssertTrue(xmas.matches(date(2099, 12, 25), calendar: calendar))
        XCTAssertFalse(xmas.matches(date(2026, 12, 24), calendar: calendar))
    }

    // MARK: - nthWeekdayOfMonth (US Mother's Day = 2nd Sunday of May)

    func test_nthWeekdayOfMonth_usMothersDay_2026() {
        // 2nd Sunday of May 2026 = May 10, 2026
        let usMothers = DayRule.nthWeekdayOfMonth(nth: 2, weekday: 1, month: 5)
        XCTAssertEqual(usMothers.resolvedDate(in: 2026, calendar: calendar), date(2026, 5, 10))
    }

    func test_nthWeekdayOfMonth_usThanksgiving_2026() {
        // 4th Thursday of November 2026 = Nov 26, 2026
        let thanksgiving = DayRule.nthWeekdayOfMonth(nth: 4, weekday: 5, month: 11)
        XCTAssertEqual(thanksgiving.resolvedDate(in: 2026, calendar: calendar), date(2026, 11, 26))
    }

    // MARK: - lastWeekdayOfMonth (FR Mother's Day = last Sunday of May)

    func test_lastWeekdayOfMonth_frMothersDay_2026() {
        // Last Sunday of May 2026 = May 31, 2026
        let frMothers = DayRule.lastWeekdayOfMonth(weekday: 1, month: 5)
        XCTAssertEqual(frMothers.resolvedDate(in: 2026, calendar: calendar), date(2026, 5, 31))
    }

    // MARK: - anniversary (matches month+day, ignores stored year)

    func test_anniversary_matches_returnsAnyYear() {
        let wedding = DayRule.anniversary(year: 2010, month: 6, day: 15)
        XCTAssertTrue(wedding.matches(date(2026, 6, 15), calendar: calendar))
        XCTAssertTrue(wedding.matches(date(2050, 6, 15), calendar: calendar))
        XCTAssertFalse(wedding.matches(date(2026, 6, 14), calendar: calendar))
    }

    // MARK: - nextOccurrence

    func test_nextOccurrence_returnsThisYearWhenInFuture() {
        let xmas = DayRule.fixedMonthDay(month: 12, day: 25)
        XCTAssertEqual(
            xmas.nextOccurrence(onOrAfter: date(2026, 6, 1), calendar: calendar),
            date(2026, 12, 25)
        )
    }

    func test_nextOccurrence_returnsNextYearWhenAlreadyPassed() {
        let xmas = DayRule.fixedMonthDay(month: 12, day: 25)
        XCTAssertEqual(
            xmas.nextOccurrence(onOrAfter: date(2026, 12, 26), calendar: calendar),
            date(2027, 12, 25)
        )
    }

    func test_nextOccurrence_includesToday() {
        let xmas = DayRule.fixedMonthDay(month: 12, day: 25)
        XCTAssertEqual(
            xmas.nextOccurrence(onOrAfter: date(2026, 12, 25), calendar: calendar),
            date(2026, 12, 25)
        )
    }

    // MARK: - Codable round-trip

    func test_codable_fixedMonthDay_roundTrip() throws {
        let original = DayRule.fixedMonthDay(month: 5, day: 1)
        let json = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayRule.self, from: json)
        XCTAssertEqual(decoded, original)
    }

    func test_codable_nthWeekday_roundTrip() throws {
        let original = DayRule.nthWeekdayOfMonth(nth: 2, weekday: 1, month: 5)
        let json = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayRule.self, from: json)
        XCTAssertEqual(decoded, original)
    }

    func test_codable_anniversary_roundTrip() throws {
        let original = DayRule.anniversary(year: 2010, month: 6, day: 15)
        let json = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayRule.self, from: json)
        XCTAssertEqual(decoded, original)
    }

    func test_codable_decodesSeedJsonFormat() throws {
        // Same shape as the Resources/ImportantDays/*.json bundles.
        let json = Data("""
        { "type": "nthWeekdayOfMonth", "n": 2, "weekday": 1, "month": 5 }
        """.utf8)
        let decoded = try JSONDecoder().decode(DayRule.self, from: json)
        XCTAssertEqual(decoded, .nthWeekdayOfMonth(nth: 2, weekday: 1, month: 5))
    }
}
