@testable import PersonalHygiene
import XCTest

final class WatchShowCompletedToggleStoreTests: XCTestCase {

    private let suite = "watchShowCompleted-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_default_showsCompleted() {
        XCTAssertTrue(WatchShowCompletedToggleStore.showCompleted(in: defaults))
    }

    func test_setFalse_persistsAcrossReads() {
        WatchShowCompletedToggleStore.set(false, in: defaults)
        XCTAssertFalse(WatchShowCompletedToggleStore.showCompleted(in: defaults))
    }

    func test_setTrue_overridesPriorFalse() {
        WatchShowCompletedToggleStore.set(false, in: defaults)
        WatchShowCompletedToggleStore.set(true, in: defaults)
        XCTAssertTrue(WatchShowCompletedToggleStore.showCompleted(in: defaults))
    }
}
