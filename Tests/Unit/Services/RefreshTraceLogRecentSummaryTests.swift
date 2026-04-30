@testable import PersonalHygiene
@preconcurrency import XCTest

@MainActor
final class RefreshTraceLogRecentSummaryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        RefreshTraceLog.shared.reset()
    }

    override func tearDown() {
        RefreshTraceLog.shared.reset()
        super.tearDown()
    }

    func test_recentSummary_emptyWhenLogIsEmpty() {
        XCTAssertTrue(RefreshTraceLog.shared.recentSummary().isEmpty)
    }

    func test_recentSummary_capsAtLimit() {
        for index in 0..<8 {
            RefreshTraceLog.shared.record(scheduledCount: index, kind: .refresh)
        }
        let lines = RefreshTraceLog.shared.recentSummary(limit: 3)
        XCTAssertEqual(lines.count, 3)
    }

    func test_recentSummary_isNewestFirst() {
        RefreshTraceLog.shared.record(scheduledCount: 1, kind: .refresh)
        RefreshTraceLog.shared.record(scheduledCount: 2, kind: .reschedule)
        let lines = RefreshTraceLog.shared.recentSummary()
        XCTAssertTrue(lines.first?.contains("reschedule") ?? false, "newest entry first")
    }
}
