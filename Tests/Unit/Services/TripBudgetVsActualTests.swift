@testable import PersonalHygiene
import XCTest

final class TripBudgetVsActualTests: XCTestCase {

    private func expense(_ amount: Double, currency: String = "EUR") -> TripExpense {
        TripExpense(
            label: "x",
            amount: amount,
            currencyCode: currency,
            occurredAt: Date()
        )
    }

    func test_summarize_filtersByCurrencyCode() {
        let summary = TripBudgetVsActual.summarize(
            budget: 1000,
            expenses: [expense(100), expense(50, currency: "USD"), expense(25)],
            currencyCode: "EUR"
        )
        XCTAssertEqual(summary.actual, 125)
        XCTAssertEqual(summary.budget, 1000)
    }

    func test_status_thresholds() {
        let under = TripBudgetVsActual.Summary(budget: 1000, actual: 500, currencyCode: "EUR")
        let on = TripBudgetVsActual.Summary(budget: 1000, actual: 1000, currencyCode: "EUR")
        let over = TripBudgetVsActual.Summary(budget: 1000, actual: 1200, currencyCode: "EUR")

        XCTAssertEqual(TripBudgetVsActual.status(for: under), .underBudget)
        XCTAssertEqual(TripBudgetVsActual.status(for: on), .onBudget)
        XCTAssertEqual(TripBudgetVsActual.status(for: over), .overBudget)
    }

    func test_summary_fraction_zeroBudget() {
        let summary = TripBudgetVsActual.Summary(budget: 0, actual: 100, currencyCode: "EUR")
        XCTAssertEqual(summary.fraction, 1)
    }
}
