@testable import PersonalHygiene
@preconcurrency import XCTest

final class WhatsNewHistoryStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.whatsnew-\(UUID().uuidString)")!
    }

    func test_history_emptyByDefault() {
        XCTAssertTrue(WhatsNewHistoryStore.history(defaults: defaults).isEmpty)
    }

    func test_record_addsNewestFirst() {
        WhatsNewHistoryStore.record(commitSHA: "abc", in: defaults)
        WhatsNewHistoryStore.record(commitSHA: "def", in: defaults)
        let entries = WhatsNewHistoryStore.history(defaults: defaults)
        XCTAssertEqual(entries.first?.commitSHA, "def")
        XCTAssertEqual(entries.last?.commitSHA, "abc")
    }

    func test_record_dedupesConsecutiveDuplicate() {
        WhatsNewHistoryStore.record(commitSHA: "abc", in: defaults)
        WhatsNewHistoryStore.record(commitSHA: "abc", in: defaults)
        XCTAssertEqual(WhatsNewHistoryStore.history(defaults: defaults).count, 1)
    }

    func test_record_capacityIsCapped() {
        for index in 0..<10 {
            WhatsNewHistoryStore.record(commitSHA: "sha-\(index)", in: defaults)
        }
        XCTAssertEqual(WhatsNewHistoryStore.history(defaults: defaults).count, WhatsNewHistoryStore.capacity)
    }
}
