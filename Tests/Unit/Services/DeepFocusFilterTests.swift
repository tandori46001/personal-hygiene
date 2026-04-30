@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class DeepFocusFilterTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    private func block(_ title: String, start: Int, duration: Int, deep: Bool) -> Block {
        Block(
            title: title,
            category: .work,
            startMinutesFromMidnight: start,
            durationMinutes: duration,
            isDeepFocus: deep
        )
    }

    func test_focusWindows_extractsOnlyDeepFocusBlocks() {
        let blocks = [
            block("Aseo", start: 7 * 60, duration: 30, deep: false),
            block("Code", start: 9 * 60, duration: 120, deep: true),
            block("Lunch", start: 13 * 60, duration: 60, deep: false),
        ]
        let windows = DeepFocusFilter.focusWindows(
            for: blocks,
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.blockTitle, "Code")
    }

    func test_isFocusActive_trueInsideWindow() {
        let blocks = [block("Code", start: 9 * 60, duration: 120, deep: true)]
        let inside = date(year: 2026, month: 4, day: 25, hour: 10)
        XCTAssertTrue(
            DeepFocusFilter.isFocusActive(at: inside, in: blocks, calendar: gregorianUTC())
        )
    }

    func test_isFocusActive_falseOnEdgeEnd() {
        let blocks = [block("Code", start: 9 * 60, duration: 120, deep: true)]
        let onEnd = date(year: 2026, month: 4, day: 25, hour: 11)
        XCTAssertFalse(
            DeepFocusFilter.isFocusActive(at: onEnd, in: blocks, calendar: gregorianUTC())
        )
    }

    func test_suppressing_dropsNonCriticalInsideWindow() {
        let window = DeepFocusFilter.FocusWindow(
            blockTitle: "Code",
            start: date(year: 2026, month: 4, day: 25, hour: 9),
            end: date(year: 2026, month: 4, day: 25, hour: 11)
        )
        let inside = ScheduledNotification(
            identifier: "a",
            title: "x",
            triggerDate: date(year: 2026, month: 4, day: 25, hour: 10),
            isCritical: false
        )
        let outside = ScheduledNotification(
            identifier: "b",
            title: "y",
            triggerDate: date(year: 2026, month: 4, day: 25, hour: 12),
            isCritical: false
        )
        let result = DeepFocusFilter.suppressing([inside, outside], focusWindows: [window])
        XCTAssertEqual(result.map(\.identifier), ["b"])
    }

    func test_suppressing_keepsCriticalInsideWindow() {
        let window = DeepFocusFilter.FocusWindow(
            blockTitle: "Code",
            start: date(year: 2026, month: 4, day: 25, hour: 9),
            end: date(year: 2026, month: 4, day: 25, hour: 11)
        )
        let pill = ScheduledNotification(
            identifier: "pill",
            title: "Pastilla",
            triggerDate: date(year: 2026, month: 4, day: 25, hour: 10),
            isCritical: true
        )
        let result = DeepFocusFilter.suppressing([pill], focusWindows: [window])
        XCTAssertEqual(result.map(\.identifier), ["pill"])
    }

    // MARK: - activeWindow (slice 10)

    func test_activeWindow_returnsScheduledWhenItOverlapsCurrentTime() {
        // 2026-04-25 is Saturday (weekday 7).
        let saturday = date(year: 2026, month: 4, day: 25, hour: 14, minute: 30)
        let scheduled = ScheduledFocusWindow(
            label: "Weekend",
            weekdays: [7],
            startMinutesFromMidnight: 14 * 60,
            endMinutesFromMidnight: 16 * 60
        )
        let result = DeepFocusFilter.activeWindow(
            at: saturday,
            in: [],
            scheduledWindows: [scheduled],
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result?.blockTitle, "Weekend")
    }

    func test_activeWindow_returnsNilWhenNothingOverlaps() {
        let blocks = [block("Code", start: 9 * 60, duration: 60, deep: true)]
        let result = DeepFocusFilter.activeWindow(
            at: date(year: 2026, month: 4, day: 25, hour: 12),
            in: blocks,
            calendar: gregorianUTC()
        )
        XCTAssertNil(result)
    }

    func test_activeWindow_blockBasedTakesPriorityWhenBothCover() {
        // Both a block and a scheduled window cover the same instant. The
        // current contract is that block-derived windows are appended first,
        // so `activeWindow.first` returns the block window.
        let saturday = date(year: 2026, month: 4, day: 25, hour: 10)
        let block = block("Code", start: 9 * 60, duration: 120, deep: true)
        let scheduled = ScheduledFocusWindow(
            label: "Scheduled",
            weekdays: [7],
            startMinutesFromMidnight: 9 * 60,
            endMinutesFromMidnight: 11 * 60
        )
        let result = DeepFocusFilter.activeWindow(
            at: saturday,
            in: [block],
            scheduledWindows: [scheduled],
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result?.blockTitle, "Code")
    }

    func test_activeWindow_scheduledIgnoresOtherWeekdays() {
        // Saturday with a Monday-only schedule → no active window.
        let saturday = date(year: 2026, month: 4, day: 25, hour: 10)
        let scheduled = ScheduledFocusWindow(
            label: "Mondays only",
            weekdays: [2],
            startMinutesFromMidnight: 9 * 60,
            endMinutesFromMidnight: 11 * 60
        )
        XCTAssertNil(
            DeepFocusFilter.activeWindow(
                at: saturday,
                in: [],
                scheduledWindows: [scheduled],
                calendar: gregorianUTC()
            )
        )
    }
}
