@testable import PersonalHygiene
import XCTest

final class PendingNotificationsGroupTests: XCTestCase {

    func test_grouped_buildsBucketsInCanonicalOrder() {
        let identifiers = [
            "personal-hygiene.hydration.2026-01-01.0",
            "personal-hygiene.block.uuid.2026-01-01",
            "personal-hygiene.medication.followup.uuid.2026-01-01",
            "personal-hygiene.trip-milestone.uuid",
            "third-party.unknown",
        ]
        let groups = PendingNotificationsGroup.grouped(identifiers)
        XCTAssertEqual(groups.count, 5)
        XCTAssertEqual(groups[0].category, .routine)
        XCTAssertEqual(groups[1].category, .medicationFollowUp)
        XCTAssertEqual(groups[2].category, .hydration)
        XCTAssertEqual(groups[3].category, .milestones)
        XCTAssertEqual(groups[4].category, .other)
    }

    func test_grouped_emptyInput_emptyOutput() {
        XCTAssertTrue(PendingNotificationsGroup.grouped([]).isEmpty)
    }

    func test_grouped_categoryWithNoIdsOmitted() {
        let groups = PendingNotificationsGroup.grouped([
            "personal-hygiene.block.uuid.2026-01-01"
        ])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].category, .routine)
    }
}
