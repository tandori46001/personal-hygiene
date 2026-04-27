@testable import PersonalHygiene
import XCTest

final class PauseNotificationsStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.pause-\(UUID().uuidString)")!
    }

    func test_isPaused_falseWhenUnset() {
        XCTAssertFalse(PauseNotificationsStore.isPaused(defaults: defaults))
        XCTAssertNil(PauseNotificationsStore.pausedUntil(defaults: defaults))
    }

    func test_pauseForHours_setsFutureDate() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        PauseNotificationsStore.pauseForHours(2, now: now, in: defaults)
        XCTAssertTrue(PauseNotificationsStore.isPaused(now: now, defaults: defaults))
        let until = PauseNotificationsStore.pausedUntil(defaults: defaults)
        XCTAssertEqual(until?.timeIntervalSince1970 ?? 0, 1_700_000_000 + 7_200, accuracy: 1)
    }

    func test_isPaused_falseAfterExpiry() {
        let then = Date(timeIntervalSince1970: 1_700_000_000)
        PauseNotificationsStore.pauseForHours(1, now: then, in: defaults)
        let later = Date(timeIntervalSince1970: 1_700_000_000 + 7_200)
        XCTAssertFalse(PauseNotificationsStore.isPaused(now: later, defaults: defaults))
    }

    func test_clear_removesPause() {
        PauseNotificationsStore.pauseForHours(1, in: defaults)
        PauseNotificationsStore.clear(in: defaults)
        XCTAssertFalse(PauseNotificationsStore.isPaused(defaults: defaults))
    }
}
