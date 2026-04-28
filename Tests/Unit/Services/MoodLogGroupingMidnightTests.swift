@testable import PersonalHygiene
import XCTest

/// Round-24 slice T1.3 — guards `MoodLogGrouping.sections(...)` at calendar
/// boundaries. An entry recorded at 23:59 vs 00:01 on adjacent days must
/// land in different sections, even when the user's calendar drifts via
/// DST (autoupdating doesn't apply DST inside a fixed-UTC test calendar,
/// but the boundary semantics are what matters).
final class MoodLogGroupingMidnightTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int = 2026, month: Int = 4, day: Int, hour: Int, minute: Int) -> Date {
        let cal = calendar()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    func test_sections_splitsEntriesAcrossMidnight() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(day: 1, hour: 23, minute: 59)),
            MoodLogStore.Entry(mood: .bad, recordedAt: date(day: 2, hour: 0, minute: 1)),
        ]
        let sections = MoodLogGrouping.sections(from: entries, calendar: calendar())
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].entries.count, 1)
        XCTAssertEqual(sections[1].entries.count, 1)
    }

    func test_sections_collapsesEntriesOnSameDayDespiteFarApart() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(day: 1, hour: 0, minute: 1)),
            MoodLogStore.Entry(mood: .bad, recordedAt: date(day: 1, hour: 23, minute: 59)),
        ]
        let sections = MoodLogGrouping.sections(from: entries, calendar: calendar())
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].entries.count, 2)
    }

    func test_todaySection_excludesYesterdayLateNight() {
        let entries = [
            MoodLogStore.Entry(mood: .bad, recordedAt: date(day: 1, hour: 23, minute: 59)),
        ]
        let result = MoodLogGrouping.todaySection(
            from: entries,
            now: date(day: 2, hour: 0, minute: 30),
            calendar: calendar()
        )
        XCTAssertNil(result, "yesterday's 23:59 entry must not show up under today's section")
    }
}
