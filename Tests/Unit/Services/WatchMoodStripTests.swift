@testable import PersonalHygiene
import XCTest

final class WatchMoodStripTests: XCTestCase {

    private let suite = "watchStripTests-\(UUID().uuidString)"
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

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ offset: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: offset, to: base)!
    }

    func test_cells_emitsExactlyDaysCells() {
        let cells = WatchMoodStrip.cells(
            days: 7,
            now: date(0),
            calendar: calendar(),
            defaults: defaults
        )
        XCTAssertEqual(cells.count, 7)
    }

    func test_cells_dotForEmptyDays_emojiForRecorded() {
        MoodLogStore.record(.great, now: date(0), in: defaults)
        let cells = WatchMoodStrip.cells(
            days: 7,
            now: date(0),
            calendar: calendar(),
            defaults: defaults
        )
        XCTAssertEqual(cells.last?.symbol, MoodLogStore.Mood.great.emoji)
        XCTAssertTrue(cells.dropLast().allSatisfy { $0.symbol == "·" })
    }
}
