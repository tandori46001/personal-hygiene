@testable import PersonalHygiene
import XCTest

/// Round-23 slice T1.3 — extra coverage on `HousekeepingCompletionLog`
/// beyond the round-22 happy-path tests. Specifically pins down behaviour
/// at calendar-day boundaries + multi-room interleaving so a later
/// refactor can't silently shift which day a midnight tap lands on.
final class HousekeepingLogIdempotencyTests: XCTestCase {

    private let suite = "housekeepingIdempotencyTests-\(UUID().uuidString)"
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

    private func date(year: Int = 2026, month: Int = 4, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let cal = calendar()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    func test_record_atDayBoundary_assignsCorrectDayKey() {
        let cal = calendar()
        // Two records 1 minute apart but straddling midnight UTC.
        HousekeepingCompletionLog.record(
            room: "kitchen",
            on: date(day: 1, hour: 23, minute: 59),
            calendar: cal,
            in: defaults
        )
        HousekeepingCompletionLog.record(
            room: "kitchen",
            on: date(day: 2, hour: 0, minute: 1),
            calendar: cal,
            in: defaults
        )
        XCTAssertEqual(HousekeepingCompletionLog.days(room: "kitchen", in: defaults).count, 2)
    }

    func test_record_doubleTapSameMinute_isIdempotent() {
        let exact = date(day: 1, hour: 12, minute: 0)
        for _ in 0..<10 {
            HousekeepingCompletionLog.record(room: "kitchen", on: exact, calendar: calendar(), in: defaults)
        }
        XCTAssertEqual(HousekeepingCompletionLog.days(room: "kitchen", in: defaults).count, 1)
    }

    func test_multiRoom_doesNotCrossContaminateDayKeys() {
        HousekeepingCompletionLog.record(room: "kitchen", on: date(day: 1), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "kitchen", on: date(day: 2), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "bath", on: date(day: 5), calendar: calendar(), in: defaults)

        XCTAssertEqual(HousekeepingCompletionLog.days(room: "kitchen", in: defaults).count, 2)
        XCTAssertEqual(HousekeepingCompletionLog.days(room: "bath", in: defaults).count, 1)
        XCTAssertTrue(
            HousekeepingCompletionLog.days(room: "kitchen", in: defaults)
                .isDisjoint(with: HousekeepingCompletionLog.days(room: "bath", in: defaults))
        )
    }

    func test_clear_removesEveryRoomEntry() {
        HousekeepingCompletionLog.record(room: "kitchen", on: date(day: 1), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "bath", on: date(day: 1), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.clear(in: defaults)
        XCTAssertTrue(HousekeepingCompletionLog.days(room: "kitchen", in: defaults).isEmpty)
        XCTAssertTrue(HousekeepingCompletionLog.days(room: "bath", in: defaults).isEmpty)
    }
}
