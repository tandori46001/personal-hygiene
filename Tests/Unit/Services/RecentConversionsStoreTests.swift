@preconcurrency import XCTest

@testable import PersonalHygiene

final class RecentConversionsStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-recents-\(UUID().uuidString)")!
    }

    override func tearDown() {
        defaults.removeObject(forKey: RecentConversionsStore.key)
        defaults = nil
        super.tearDown()
    }

    private func record(_ from: String, _ to: String, _ amount: Double, _ converted: Double) {
        let conv = CurrencyConversion(from: from, to: to, rate: converted / amount, amountConverted: converted)
        RecentConversionsStore.record(conv, amount: amount, in: defaults)
    }

    func test_recent_emptyByDefault() {
        XCTAssertTrue(RecentConversionsStore.recent(defaults: defaults).isEmpty)
    }

    func test_record_persistsAndReturnsNewestFirst() {
        record("EUR", "USD", 100, 110)
        record("EUR", "GBP", 100, 86)
        let entries = RecentConversionsStore.recent(defaults: defaults)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.first?.to, "GBP")
        XCTAssertEqual(entries.last?.to, "USD")
    }

    func test_record_dedupesByFromToAmount() {
        record("EUR", "USD", 100, 110)
        record("EUR", "USD", 100, 112)  // newer rate, same triple
        let entries = RecentConversionsStore.recent(defaults: defaults)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.amountConverted, 112)
    }

    func test_record_capacityCappedToFive() {
        for index in 0..<7 {
            record("EUR", "USD", Double(index + 1) * 10, Double(index + 1) * 11)
        }
        XCTAssertEqual(RecentConversionsStore.recent(defaults: defaults).count, RecentConversionsStore.capacity)
    }

    func test_clear_removesAll() {
        record("EUR", "USD", 100, 110)
        RecentConversionsStore.clear(in: defaults)
        XCTAssertTrue(RecentConversionsStore.recent(defaults: defaults).isEmpty)
    }
}
