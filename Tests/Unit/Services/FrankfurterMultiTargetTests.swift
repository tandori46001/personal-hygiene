import XCTest

@testable import PersonalHygiene

final class FrankfurterMultiTargetTests: XCTestCase {

    func test_parseAll_returnsOneConversionPerRate() throws {
        let json = """
        {
            "amount": 100,
            "base": "EUR",
            "rates": {
                "USD": 110.0,
                "GBP": 86.5,
                "JPY": 17000.0
            }
        }
        """
        let data = Data(json.utf8)

        let results = try FrankfurterCurrencyService.parseAll(data, amount: 100, from: "EUR")

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(Set(results.map(\.to)), ["USD", "GBP", "JPY"])
        for result in results {
            XCTAssertEqual(result.from, "EUR")
        }
        let usd = results.first { $0.to == "USD" }
        XCTAssertEqual(usd?.amountConverted, 110)
        XCTAssertEqual(usd?.rate, 1.1)
    }

    func test_parseAll_zeroAmountFallsBackToConverted() throws {
        let data = Data(#"{"amount": 0, "base": "EUR", "rates": {"USD": 0.0}}"#.utf8)
        let results = try FrankfurterCurrencyService.parseAll(data, amount: 0, from: "EUR")
        XCTAssertEqual(results.first?.rate, 0)
    }

    func test_parseAll_invalidJSONThrows() {
        let data = Data("not json".utf8)
        XCTAssertThrowsError(try FrankfurterCurrencyService.parseAll(data, amount: 100, from: "EUR"))
    }
}
