@testable import PersonalHygiene
import XCTest

/// Round-23 slice T1.4 — extends round-22's reconciler coverage with edge
/// cases: a fail-on-first scenario must NOT clear the queue (otherwise the
/// user loses log entries permanently). Also covers a 0-amount entry that
/// the appender refuses to write but a hand-injected payload could carry.
@MainActor
final class WatchHydrationReconcilerTailTests: XCTestCase {

    private final class FlakyService: HydrationService {
        var logged: [Int] = []
        var failOnIndex: Int?
        func log(milliliters: Int, at drankAt: Date) throws {
            if let failOnIndex, logged.count == failOnIndex {
                throw NSError(domain: "test", code: 1)
            }
            logged.append(milliliters)
        }
        func logs(between start: Date, and end: Date) throws -> [HydrationLog] { [] }
        func deleteAllLogs() throws {}
        func delete(_ log: HydrationLog) throws {}
    }

    override func setUp() {
        super.setUp()
        WatchHydrationGlanceStore.clearPending()
    }

    override func tearDown() {
        WatchHydrationGlanceStore.clearPending()
        super.tearDown()
    }

    func test_drain_failOnFirst_keepsEntireQueue() {
        let service = FlakyService()
        service.failOnIndex = 0
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 100)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 200)

        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 0)
        XCTAssertEqual(WatchHydrationGlanceStore.pendingTaps(), [100, 200],
                       "queue is preserved exactly when zero taps land")
    }

    func test_drain_failOnLast_keepsOnlyTheFailingTap() {
        let service = FlakyService()
        service.failOnIndex = 2
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 100)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 200)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 300)

        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 2)
        XCTAssertEqual(WatchHydrationGlanceStore.pendingTaps(), [300])
    }

    func test_drain_runOnEmptyQueueIsCheap() {
        let service = FlakyService()
        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 0)
        XCTAssertTrue(service.logged.isEmpty)
    }
}
