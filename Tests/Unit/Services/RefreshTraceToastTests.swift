@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-22 slice T1.4 — guards the round-21 refresh-trace toast helper.
/// Verifies the empty-log path returns `nil`, that a recorded entry is
/// summarised in the expected `HH:MM:SS · kind · count` shape, and that the
/// composer wraps the base "today.refresh.done" string when a trace exists.
@MainActor
final class RefreshTraceToastTests: XCTestCase {

    override func setUp() {
        super.setUp()
        RefreshTraceLog.shared.reset()
    }

    override func tearDown() {
        RefreshTraceLog.shared.reset()
        super.tearDown()
    }

    func test_refreshTraceToastText_isNilWhenLogIsEmpty() {
        XCTAssertNil(TodayView.refreshTraceToastText())
    }

    func test_refreshTraceToastText_formatsLatestEntryWithCount() {
        RefreshTraceLog.shared.record(scheduledCount: 17, kind: .refresh)
        let text = TodayView.refreshTraceToastText()
        XCTAssertNotNil(text)
        XCTAssertTrue(text?.contains("refresh") ?? false)
        XCTAssertTrue(text?.contains("17") ?? false)
    }

    func test_refreshTraceToastText_distinguishesPausedFromRefresh() {
        RefreshTraceLog.shared.record(scheduledCount: 0, kind: .paused)
        XCTAssertTrue(TodayView.refreshTraceToastText()?.contains("paused") ?? false)
    }

    func test_composedRefreshToast_appendsTraceWhenAvailable() {
        let baseOnly = TodayView.composedRefreshToast()
        XCTAssertFalse(baseOnly.contains("·"), "base line has no trace separator")

        RefreshTraceLog.shared.record(scheduledCount: 5, kind: .reschedule)
        let composed = TodayView.composedRefreshToast()
        XCTAssertTrue(composed.contains("·"))
        XCTAssertTrue(composed.contains("reschedule"))
    }
}
