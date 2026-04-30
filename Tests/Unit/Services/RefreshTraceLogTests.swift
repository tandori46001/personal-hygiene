@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class RefreshTraceLogTests: XCTestCase {

    func test_record_appendsEntry() {
        let log = RefreshTraceLog(capacity: 5)
        log.record(scheduledCount: 3, kind: .refresh, at: Date(timeIntervalSince1970: 100))
        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.entries.first?.scheduledCount, 3)
        XCTAssertEqual(log.entries.first?.kind, .refresh)
    }

    func test_record_dropsOldestWhenCapacityExceeded() {
        let log = RefreshTraceLog(capacity: 2)
        log.record(scheduledCount: 1, kind: .refresh)
        log.record(scheduledCount: 2, kind: .refresh)
        log.record(scheduledCount: 3, kind: .reschedule)
        XCTAssertEqual(log.entries.count, 2)
        XCTAssertEqual(log.entries.map(\.scheduledCount), [2, 3])
    }

    func test_newestFirst_reversesOrder() {
        let log = RefreshTraceLog(capacity: 3)
        log.record(scheduledCount: 1, kind: .refresh)
        log.record(scheduledCount: 2, kind: .refresh)
        XCTAssertEqual(log.newestFirst.map(\.scheduledCount), [2, 1])
    }

    func test_reset_clearsAllEntries() {
        let log = RefreshTraceLog()
        log.record(scheduledCount: 5, kind: .refresh)
        log.reset()
        XCTAssertTrue(log.entries.isEmpty)
    }
}
