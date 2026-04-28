@testable import PersonalHygiene
import XCTest

final class TripExpenseMonthlySummaryTests: XCTestCase {

    private func date(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: 12
        ).date!
    }

    func test_empty_returnsEmpty() {
        XCTAssertTrue(TripExpenseMonthlySummary.buckets(from: []).isEmpty)
    }

    func test_singleMonthSingleCurrency_collapses() {
        let expenses = [
            TripExpense(label: "A", amount: 10, currencyCode: "EUR", occurredAt: date(year: 2026, month: 4, day: 5)),
            TripExpense(label: "B", amount: 20, currencyCode: "EUR", occurredAt: date(year: 2026, month: 4, day: 7)),
        ]
        let buckets = TripExpenseMonthlySummary.buckets(from: expenses)
        XCTAssertEqual(buckets.count, 1)
        XCTAssertEqual(buckets[0].total, 30)
        XCTAssertEqual(buckets[0].count, 2)
        XCTAssertEqual(buckets[0].currencyCode, "EUR")
        XCTAssertEqual(buckets[0].year, 2026)
        XCTAssertEqual(buckets[0].month, 4)
    }

    func test_multipleCurrenciesSameMonth_splitsByCurrency() {
        let expenses = [
            TripExpense(label: "A", amount: 10, currencyCode: "EUR", occurredAt: date(year: 2026, month: 4, day: 5)),
            TripExpense(label: "B", amount: 12, currencyCode: "USD", occurredAt: date(year: 2026, month: 4, day: 6)),
        ]
        let buckets = TripExpenseMonthlySummary.buckets(from: expenses)
        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(Set(buckets.map(\.currencyCode)), ["EUR", "USD"])
    }

    func test_multipleMonths_sortedNewestFirst() {
        let expenses = [
            TripExpense(label: "A", amount: 10, currencyCode: "EUR", occurredAt: date(year: 2026, month: 1, day: 5)),
            TripExpense(label: "B", amount: 20, currencyCode: "EUR", occurredAt: date(year: 2026, month: 4, day: 5)),
        ]
        let buckets = TripExpenseMonthlySummary.buckets(from: expenses)
        XCTAssertEqual(buckets.first?.month, 4)
        XCTAssertEqual(buckets.last?.month, 1)
    }
}
