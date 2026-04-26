import XCTest

@testable import PersonalHygiene

final class FrankfurterCurrencyServiceTests: XCTestCase {

    func test_parse_extractsAmountAndPerUnitRate() throws {
        let jsonString = """
            {
              "amount": 100.0,
              "base": "EUR",
              "date": "2026-04-25",
              "rates": { "USD": 108.5 }
            }
            """
        let json = Data(jsonString.utf8)

        let result = try FrankfurterCurrencyService.parse(json, amount: 100, from: "EUR", to: "USD")

        XCTAssertEqual(result.from, "EUR")
        XCTAssertEqual(result.to, "USD")
        XCTAssertEqual(result.amountConverted, 108.5)
        XCTAssertEqual(result.rate, 1.085, accuracy: 0.0001)
    }

    func test_parse_throwsRateNotFoundWhenTargetMissing() {
        let jsonString = """
            {
              "amount": 100.0,
              "base": "EUR",
              "date": "2026-04-25",
              "rates": { "GBP": 88.0 }
            }
            """
        let json = Data(jsonString.utf8)

        XCTAssertThrowsError(
            try FrankfurterCurrencyService.parse(json, amount: 100, from: "EUR", to: "USD")
        ) { error in
            XCTAssertEqual(error as? CurrencyError, .rateNotFound)
        }
    }

    func test_parse_throwsDecodingFailedOnGarbage() {
        let json = Data("not-json".utf8)
        XCTAssertThrowsError(
            try FrankfurterCurrencyService.parse(json, amount: 1, from: "EUR", to: "USD")
        ) { error in
            XCTAssertEqual(error as? CurrencyError, .decodingFailed)
        }
    }

    func test_parse_isCaseInsensitiveOnTargetCurrency() throws {
        let jsonString = """
            { "amount": 1.0, "base": "EUR", "date": "x", "rates": { "USD": 1.085 } }
            """
        let json = Data(jsonString.utf8)
        let result = try FrankfurterCurrencyService.parse(json, amount: 1, from: "eur", to: "usd")
        XCTAssertEqual(result.amountConverted, 1.085)
    }
}
