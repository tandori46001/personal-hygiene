@testable import PersonalHygiene
import XCTest

final class WatchHydrationGlanceStoreTests: XCTestCase {

    private let suite = "watchHydrationTests-\(UUID().uuidString)"
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

    func test_setTotal_andRetrieveOnSameDay() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        WatchHydrationGlanceStore.setTotal(750, on: day, in: defaults)
        XCTAssertEqual(WatchHydrationGlanceStore.todayTotal(on: day, in: defaults), 750)
    }

    func test_totalReadsZero_whenStoredDayIsStale() {
        let oldDay = Date(timeIntervalSince1970: 1_700_000_000)
        let newDay = oldDay.addingTimeInterval(86_400 * 2)
        WatchHydrationGlanceStore.setTotal(750, on: oldDay, in: defaults)
        XCTAssertEqual(WatchHydrationGlanceStore.todayTotal(on: newDay, in: defaults), 0)
    }

    func test_pendingTaps_appendAndClear() {
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 250, in: defaults)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 330, in: defaults)
        XCTAssertEqual(WatchHydrationGlanceStore.pendingTaps(in: defaults), [250, 330])
        WatchHydrationGlanceStore.clearPending(in: defaults)
        XCTAssertTrue(WatchHydrationGlanceStore.pendingTaps(in: defaults).isEmpty)
    }

    func test_appendPendingTap_ignoresZeroAndNegative() {
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 0, in: defaults)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: -10, in: defaults)
        XCTAssertTrue(WatchHydrationGlanceStore.pendingTaps(in: defaults).isEmpty)
    }
}
