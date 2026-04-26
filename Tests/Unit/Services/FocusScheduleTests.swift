import XCTest

@testable import PersonalHygiene

final class FocusScheduleTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    func test_window_returnsNilWhenWeekdayNotMatched() {
        // 2026-04-25 was a Saturday → weekday 7
        let window = ScheduledFocusWindow(
            label: "Sleep",
            weekdays: [2, 3, 4, 5, 6],  // Mon-Fri
            startMinutesFromMidnight: 22 * 60,
            endMinutesFromMidnight: 23 * 60
        )
        XCTAssertNil(window.window(on: date(year: 2026, month: 4, day: 25), calendar: calendar))
    }

    func test_window_returnsBoundsForActiveWeekday() {
        // 2026-04-27 is a Monday
        let window = ScheduledFocusWindow(
            label: "Sleep",
            weekdays: [2],
            startMinutesFromMidnight: 22 * 60,
            endMinutesFromMidnight: 23 * 60
        )
        let result = window.window(on: date(year: 2026, month: 4, day: 27), calendar: calendar)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.start, date(year: 2026, month: 4, day: 27, hour: 22))
        XCTAssertEqual(result?.end, date(year: 2026, month: 4, day: 27, hour: 23))
    }

    func test_isActive_falseWhenWeekdaysEmpty() {
        let window = ScheduledFocusWindow(
            label: "Idle",
            weekdays: [],
            startMinutesFromMidnight: 0,
            endMinutesFromMidnight: 60
        )
        XCTAssertFalse(window.isActive)
    }

    func test_focusFilter_combinesBlockAndScheduleSources() {
        let block = Block(
            title: "Sleep",
            category: .sleep,
            startMinutesFromMidnight: 23 * 60,
            durationMinutes: 60,
            isDeepFocus: true
        )
        let scheduled = ScheduledFocusWindow(
            label: "Quiet",
            weekdays: Set(1...7),
            startMinutesFromMidnight: 13 * 60,
            endMinutesFromMidnight: 14 * 60
        )
        let windows = DeepFocusFilter.focusWindows(
            for: [block],
            on: date(year: 2026, month: 4, day: 27),
            scheduledWindows: [scheduled],
            calendar: calendar
        )
        XCTAssertEqual(windows.count, 2)
        XCTAssertTrue(windows.contains { $0.blockTitle == "Sleep" })
        XCTAssertTrue(windows.contains { $0.blockTitle == "Quiet" })
    }

    func test_userDefaultsStore_roundTrip() {
        let defaults = UserDefaults(suiteName: "FocusScheduleStore-\(UUID().uuidString)")!
        defer { defaults.removeObject(forKey: UserDefaultsFocusScheduleStore.storageKey) }
        let store = UserDefaultsFocusScheduleStore(defaults: defaults)
        XCTAssertTrue(store.windows().isEmpty)

        let entry = ScheduledFocusWindow(
            label: "Sleep",
            weekdays: [2],
            startMinutesFromMidnight: 22 * 60,
            endMinutesFromMidnight: 23 * 60
        )
        store.upsert(entry)

        let read = store.windows()
        XCTAssertEqual(read.count, 1)
        XCTAssertEqual(read.first?.label, "Sleep")

        store.delete(id: entry.id)
        XCTAssertTrue(store.windows().isEmpty)
    }
}
