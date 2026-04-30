@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-25 slice T1.3: applying the same target category twice yields the
/// same observable state — proves the helper is idempotent and safe to
/// retry from the bulk-edit sheet without corrupting blocks.
final class BulkCategoryEditorIdempotencyTests: XCTestCase {

    func test_apply_twice_isObservablyEqualToOnce() {
        let blocks = [
            Block(title: "A", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 30),
            Block(title: "B", category: .hygiene, startMinutesFromMidnight: 10 * 60, durationMinutes: 30),
        ]
        let once = BulkCategoryEditor.apply(category: .meal, to: blocks)
        let twice = BulkCategoryEditor.apply(category: .meal, to: once)
        XCTAssertEqual(once.map(\.category), twice.map(\.category))
        XCTAssertTrue(twice.allSatisfy { $0.category == .meal })
    }

    func test_apply_doesNotMutateUnrelatedFields() {
        let blocks = [
            Block(
                title: "A",
                category: .work,
                startMinutesFromMidnight: 9 * 60,
                durationMinutes: 30,
                notes: "preserve me",
                notificationLeadMinutes: 5,
                isDeepFocus: true
            )
        ]
        let updated = BulkCategoryEditor.apply(category: .meal, to: blocks)
        let block = updated.first!
        XCTAssertEqual(block.title, "A")
        XCTAssertEqual(block.notes, "preserve me")
        XCTAssertEqual(block.notificationLeadMinutes, 5)
        XCTAssertTrue(block.isDeepFocus)
        XCTAssertEqual(block.startMinutesFromMidnight, 9 * 60)
        XCTAssertEqual(block.durationMinutes, 30)
    }
}
