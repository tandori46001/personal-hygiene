@testable import PersonalHygiene
import XCTest

@MainActor
final class WatchHydrationReconcilerTests: XCTestCase {

    @MainActor
    private final class CountingService: HydrationService {
        var logged: [(milliliters: Int, drankAt: Date)] = []
        var failOnIndex: Int?
        func log(milliliters: Int, at drankAt: Date) throws {
            if let failOnIndex, logged.count == failOnIndex {
                throw NSError(domain: "test", code: 1)
            }
            logged.append((milliliters, drankAt))
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

    func test_drain_doesNothingWhenQueueEmpty() {
        let service = CountingService()
        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 0)
        XCTAssertTrue(service.logged.isEmpty)
    }

    func test_drain_landsAllAndClearsQueue() {
        let service = CountingService()
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 250)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 330)

        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 2)
        XCTAssertEqual(service.logged.count, 2)
        XCTAssertTrue(WatchHydrationGlanceStore.pendingTaps().isEmpty)
    }

    func test_drain_partialFailureKeepsTail() {
        let service = CountingService()
        service.failOnIndex = 1
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 100)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 200)
        WatchHydrationGlanceStore.appendPendingTap(amountMl: 300)

        let landed = WatchHydrationReconciler.drain(into: service)
        XCTAssertEqual(landed, 1, "first one logs, second fails")
        XCTAssertEqual(service.logged.first?.milliliters, 100)
        XCTAssertEqual(WatchHydrationGlanceStore.pendingTaps(), [200, 300])
    }
}
