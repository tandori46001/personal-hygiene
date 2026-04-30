@testable import PersonalHygiene
@preconcurrency import XCTest

final class MedicationMissedDoseAlertHelperTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func now(hour: Int, minute: Int = 0) -> Date {
        let cal = calendar()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28,
            hour: hour, minute: minute
        ).date!
    }

    private func medicationBlock(at hour: Int, title: String = "Take A") -> Block {
        Block(
            title: title,
            category: .medication,
            startMinutesFromMidnight: hour * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-1"
        )
    }

    func test_nextMissed_nilWhenNoMedicationBlocks() {
        let blocks = [
            Block(title: "Work", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 30)
        ]
        let candidate = MedicationMissedDoseAlertHelper.nextMissed(
            blocks: blocks,
            completionsToday: [],
            now: now(hour: 12),
            calendar: calendar()
        )
        XCTAssertNil(candidate)
    }

    func test_nextMissed_returnsLatestPastUncompleted() {
        let morning = medicationBlock(at: 8, title: "Morning")
        let noon = medicationBlock(at: 12, title: "Noon")
        let evening = medicationBlock(at: 20, title: "Evening")
        let candidate = MedicationMissedDoseAlertHelper.nextMissed(
            blocks: [morning, noon, evening],
            completionsToday: [],
            now: now(hour: 15),
            calendar: calendar()
        )
        XCTAssertEqual(candidate?.blockTitle, "Noon")
    }

    func test_nextMissed_ignoresCompletedBlocks() {
        let morning = medicationBlock(at: 8, title: "Morning")
        let noon = medicationBlock(at: 12, title: "Noon")
        let candidate = MedicationMissedDoseAlertHelper.nextMissed(
            blocks: [morning, noon],
            completionsToday: [noon.id],
            now: now(hour: 15),
            calendar: calendar()
        )
        XCTAssertEqual(candidate?.blockTitle, "Morning")
    }

    func test_nextMissed_nilWhenAllInFuture() {
        let evening = medicationBlock(at: 20, title: "Evening")
        let candidate = MedicationMissedDoseAlertHelper.nextMissed(
            blocks: [evening],
            completionsToday: [],
            now: now(hour: 8),
            calendar: calendar()
        )
        XCTAssertNil(candidate)
    }
}
