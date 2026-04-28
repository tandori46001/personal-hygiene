@testable import PersonalHygiene
import XCTest

final class CurrencyRatesCSVTests: XCTestCase {

    func test_render_emitsHeaderAndOneRowPerConversion() {
        let conversions = [
            CurrencyConversion(from: "EUR", to: "USD", rate: 1.085, amountConverted: 108.5),
            CurrencyConversion(from: "EUR", to: "JPY", rate: 162.3, amountConverted: 16_230),
        ]
        let csv = CurrencyRatesCSV.render(amount: 100, from: "eur", conversions: conversions)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(String(lines[0]), "base,target,rate,converted")
        XCTAssertTrue(lines[1].hasPrefix("EUR,USD,"))
        XCTAssertTrue(lines[1].hasSuffix(",108.50"))
    }

    func test_render_emptyConversions_emitsHeaderOnly() {
        let csv = CurrencyRatesCSV.render(amount: 100, from: "EUR", conversions: [])
        XCTAssertEqual(csv, "base,target,rate,converted")
    }
}
