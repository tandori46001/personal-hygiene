@testable import PersonalHygiene
import XCTest

final class PendingNotificationsByCategoryTests: XCTestCase {

    func test_classify_groupsByPrefix() {
        let counts = PendingNotificationsByCategory.classify([
            "personal-hygiene.block.1.2025-04-27",
            "personal-hygiene.block.2.2025-04-27",
            "personal-hygiene.medication.followup.5.2025-04-27",
            "personal-hygiene.hydration.2025-04-27.0",
            "personal-hygiene.hydration.2025-04-27.1",
            "personal-hygiene.trip-milestone.x",
            "personal-hygiene.housekeeping.y",
            "third-party.unknown.thing",
        ])
        XCTAssertEqual(counts.routine, 2)
        XCTAssertEqual(counts.medicationFollowUp, 1)
        XCTAssertEqual(counts.hydration, 2)
        XCTAssertEqual(counts.milestones, 1)
        XCTAssertEqual(counts.housekeeping, 1)
        XCTAssertEqual(counts.other, 1)
        XCTAssertEqual(counts.total, 8)
    }

    func test_classify_emptyInput() {
        let counts = PendingNotificationsByCategory.classify([])
        XCTAssertEqual(counts.total, 0)
    }

    func test_classify_followUpPrefix_takesPrecedenceOverRoutine() {
        // The follow-up prefix starts with `personal-hygiene.medication.followup.`
        // which would also match against any naive substring check for the
        // routine prefix. The classifier checks the follow-up prefix first.
        let counts = PendingNotificationsByCategory.classify([
            "personal-hygiene.medication.followup.abc"
        ])
        XCTAssertEqual(counts.medicationFollowUp, 1)
        XCTAssertEqual(counts.routine, 0)
    }
}
