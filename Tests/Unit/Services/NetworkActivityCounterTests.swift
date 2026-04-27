@testable import PersonalHygiene
import XCTest

final class NetworkActivityCounterTests: XCTestCase {

    private var counter: NetworkActivityCounter!

    override func setUp() {
        super.setUp()
        counter = NetworkActivityCounter()
    }

    func test_record_incrementsCount() {
        counter.record(.frankfurter)
        counter.record(.frankfurter)
        counter.record(.openMeteo)
        XCTAssertEqual(counter.count(for: .frankfurter), 2)
        XCTAssertEqual(counter.count(for: .openMeteo), 1)
        XCTAssertEqual(counter.count(for: .advisory), 0)
    }

    func test_lastFired_tracksTimestamp() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        counter.record(.frankfurter, at: date)
        XCTAssertEqual(counter.lastFired(for: .frankfurter)?.timeIntervalSince1970, 1_700_000_000)
    }

    func test_reset_clearsAll() {
        counter.record(.frankfurter)
        counter.record(.openMeteo)
        counter.reset()
        XCTAssertEqual(counter.count(for: .frankfurter), 0)
        XCTAssertEqual(counter.count(for: .openMeteo), 0)
    }
}
