@testable import PersonalHygiene
@preconcurrency import XCTest

final class BedtimeMuteTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    private func makeBlock(startMinutes: Int, durationMinutes: Int) -> Block {
        Block(
            title: "Sleep",
            category: .sleep,
            startMinutesFromMidnight: startMinutes,
            durationMinutes: durationMinutes
        )
    }

    private func makeNotification(at minutesFromMidnight: Int, on day: Date) -> ScheduledNotification {
        let dayStart = cal.startOfDay(for: day)
        let trigger = cal.date(byAdding: .minute, value: minutesFromMidnight, to: dayStart)!
        return ScheduledNotification(
            identifier: "test.\(minutesFromMidnight)",
            title: "Hydrate",
            body: nil,
            triggerDate: trigger,
            isCritical: false
        )
    }

    func test_shouldSuppress_nilBlock_falseAlways() {
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let notif = makeNotification(at: 22 * 60, on: day)
        XCTAssertFalse(BedtimeMute.shouldSuppress(
            notification: notif,
            sleepBlock: nil,
            on: day,
            calendar: cal
        ))
    }

    func test_shouldSuppress_insideWindow_true() {
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        // sleep block 22:00 → 06:00 next day (8h)
        let block = makeBlock(startMinutes: 22 * 60, durationMinutes: 8 * 60)
        let notif = makeNotification(at: 23 * 60, on: day)
        XCTAssertTrue(BedtimeMute.shouldSuppress(
            notification: notif,
            sleepBlock: block,
            on: day,
            calendar: cal
        ))
    }

    func test_shouldSuppress_outsideWindow_false() {
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let block = makeBlock(startMinutes: 22 * 60, durationMinutes: 8 * 60)
        let notif = makeNotification(at: 12 * 60, on: day)
        XCTAssertFalse(BedtimeMute.shouldSuppress(
            notification: notif,
            sleepBlock: block,
            on: day,
            calendar: cal
        ))
    }

    func test_shouldSuppress_withinBuffer_true() {
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let block = makeBlock(startMinutes: 22 * 60, durationMinutes: 8 * 60)
        // 5 minutes before block start (still within 15-min buffer)
        let notif = makeNotification(at: 22 * 60 - 5, on: day)
        XCTAssertTrue(BedtimeMute.shouldSuppress(
            notification: notif,
            sleepBlock: block,
            on: day,
            calendar: cal
        ))
    }
}
