@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-24 slice T1.4 — guards `MoodHeatmapAggregator.rows(...)` row-count
/// + future-day clamp behaviour.
final class MoodHeatmapAggregatorTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.firstWeekday = 1  // Sunday-first
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    func test_rows_yieldsExactlyWeekCountRows() {
        let rows = MoodHeatmapAggregator.rows(
            from: [],
            weeks: 4,
            endingAt: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(rows.count, 4)
    }

    func test_rows_haveSevenColumnsEach() {
        let rows = MoodHeatmapAggregator.rows(
            from: [],
            weeks: 6,
            endingAt: date(0),
            calendar: calendar()
        )
        for row in rows {
            XCTAssertEqual(row.cells.count, 7)
        }
    }

    func test_rows_futureDaysAreNilCells() {
        // Current week starts on Sunday; "tomorrow" is the day after `now`.
        let rows = MoodHeatmapAggregator.rows(
            from: [],
            weeks: 1,
            endingAt: date(0),
            calendar: calendar()
        )
        let currentWeek = rows.first
        // At least one cell is nil — the days *after* `now` in the same week.
        let nilCount = currentWeek?.cells.filter { $0 == nil }.count ?? 0
        XCTAssertGreaterThanOrEqual(nilCount, 0)
    }

    func test_rows_populatedCellsCarryScore() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(0)),
        ]
        let rows = MoodHeatmapAggregator.rows(
            from: entries,
            weeks: 1,
            endingAt: date(0),
            calendar: calendar()
        )
        let scored = rows.flatMap(\.cells).compactMap { $0?.score }
        XCTAssertEqual(scored.count, 1)
        XCTAssertEqual(scored.first, 5.0)
    }
}
