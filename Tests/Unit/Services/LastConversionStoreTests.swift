@testable import PersonalHygiene
import XCTest

final class LastConversionStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.last-conversion-\(UUID().uuidString)")!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.dictionaryRepresentation().keys.first ?? "")
        defaults = nil
        super.tearDown()
    }

    func test_save_and_load_roundtrip() {
        let conv = CurrencyConversion(from: "EUR", to: "USD", rate: 1.07, amountConverted: 107)
        LastConversionStore.save(conv, amount: 100, in: defaults)
        let loaded = LastConversionStore.load(defaults: defaults)
        XCTAssertEqual(loaded?.from, "EUR")
        XCTAssertEqual(loaded?.to, "USD")
        XCTAssertEqual(loaded?.amount, 100)
        XCTAssertEqual(loaded?.rate, 1.07)
        XCTAssertEqual(loaded?.amountConverted, 107)
    }

    func test_load_emptyReturnsNil() {
        XCTAssertNil(LastConversionStore.load(defaults: defaults))
    }

    func test_clear_removesEntry() {
        let conv = CurrencyConversion(from: "EUR", to: "USD", rate: 1.07, amountConverted: 107)
        LastConversionStore.save(conv, amount: 100, in: defaults)
        LastConversionStore.clear(in: defaults)
        XCTAssertNil(LastConversionStore.load(defaults: defaults))
    }

    func test_save_overwritesPrevious() {
        LastConversionStore.save(
            CurrencyConversion(from: "EUR", to: "USD", rate: 1.07, amountConverted: 107),
            amount: 100,
            in: defaults
        )
        LastConversionStore.save(
            CurrencyConversion(from: "EUR", to: "GBP", rate: 0.85, amountConverted: 85),
            amount: 100,
            in: defaults
        )
        XCTAssertEqual(LastConversionStore.load(defaults: defaults)?.to, "GBP")
    }
}
