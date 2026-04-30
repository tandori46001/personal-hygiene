@testable import PersonalHygiene
@preconcurrency import XCTest

final class MoodLogGroupingTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int, hour: Int = 12) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: hour
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    func test_sections_groupsEntriesByCalendarDay() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(0, hour: 9)),
            MoodLogStore.Entry(mood: .bad, recordedAt: date(0, hour: 18)),
            MoodLogStore.Entry(mood: .okay, recordedAt: date(-1)),
        ]
        let sections = MoodLogGrouping.sections(from: entries, calendar: calendar())
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].entries.count, 2, "two entries on day 0")
        XCTAssertEqual(sections[1].entries.count, 1)
    }

    func test_sections_areSortedNewestDayFirst() {
        let entries = [
            MoodLogStore.Entry(mood: .good, recordedAt: date(-5)),
            MoodLogStore.Entry(mood: .good, recordedAt: date(0)),
        ]
        let sections = MoodLogGrouping.sections(from: entries, calendar: calendar())
        XCTAssertGreaterThan(sections[0].day, sections[1].day)
    }

    func test_todaySection_returnsOnlyTodayEntries() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(0, hour: 9)),
            MoodLogStore.Entry(mood: .okay, recordedAt: date(-1)),
        ]
        let today = MoodLogGrouping.todaySection(
            from: entries,
            now: date(0, hour: 23),
            calendar: calendar()
        )
        XCTAssertEqual(today?.entries.count, 1)
    }

    func test_todaySection_returnsNilWhenEmpty() {
        let today = MoodLogGrouping.todaySection(
            from: [],
            now: date(0),
            calendar: calendar()
        )
        XCTAssertNil(today)
    }
}
