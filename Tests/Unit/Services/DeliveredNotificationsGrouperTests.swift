import XCTest

@testable import PersonalHygiene

final class DeliveredNotificationsGrouperTests: XCTestCase {

    private func item(_ identifier: String, deliveredAt: TimeInterval) -> DeliveredNotificationsGrouper.Item {
        DeliveredNotificationsGrouper.Item(
            identifier: identifier,
            title: "T",
            body: "B",
            deliveredAt: Date(timeIntervalSince1970: deliveredAt)
        )
    }

    func test_group_emptyInputProducesEmptyOutput() {
        XCTAssertEqual(DeliveredNotificationsGrouper.group([]), [])
    }

    func test_group_bucketsBySourceInAllCasesOrder() {
        let blockID = UUID()
        let milestoneID = UUID()
        let medID = UUID()
        let items: [DeliveredNotificationsGrouper.Item] = [
            item("personal-hygiene.hydration.2026-04-25.0", deliveredAt: 100),
            item("personal-hygiene.trip-milestone.\(milestoneID.uuidString)", deliveredAt: 200),
            item("personal-hygiene.medication.followup.\(medID.uuidString).2026-04-25", deliveredAt: 300),
            item("personal-hygiene.block.\(blockID.uuidString).2026-04-25", deliveredAt: 400),
        ]

        let groups = DeliveredNotificationsGrouper.group(items)
        let sources = groups.map(\.source)

        XCTAssertEqual(sources, [.routine, .hydration, .milestone, .medicationFollowUp])
        XCTAssertEqual(groups.count, 4)
        XCTAssertTrue(groups.allSatisfy { $0.items.count == 1 })
    }

    func test_group_unknownIdentifierFallsIntoTrailingNilSource() {
        let blockID = UUID()
        let items: [DeliveredNotificationsGrouper.Item] = [
            item("com.apple.system.timezone", deliveredAt: 100),
            item("personal-hygiene.block.\(blockID.uuidString).2026-04-25", deliveredAt: 200),
            item("totally-unrelated", deliveredAt: 300),
        ]

        let groups = DeliveredNotificationsGrouper.group(items)

        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups.first?.source, .routine)
        XCTAssertNil(groups.last?.source)
        XCTAssertEqual(groups.last?.items.count, 2)
    }

    func test_group_sortsItemsWithinBucketNewestFirst() {
        let blockID = UUID()
        let identifier = "personal-hygiene.block.\(blockID.uuidString).2026-04-25"
        let items: [DeliveredNotificationsGrouper.Item] = [
            item(identifier, deliveredAt: 100),
            item(identifier + "x", deliveredAt: 500),
            item(identifier + "y", deliveredAt: 300),
        ]

        let group = DeliveredNotificationsGrouper.group(items).first
        XCTAssertEqual(group?.source, .routine)
        XCTAssertEqual(group?.items.map(\.deliveredAt.timeIntervalSince1970), [500, 300, 100])
    }
}
