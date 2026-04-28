@testable import PersonalHygiene
import XCTest

final class BulkCategoryEditorTests: XCTestCase {

    func test_apply_setsCategoryOnEveryBlock() {
        let blocks = [
            Block(title: "A", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 30),
            Block(title: "B", category: .hygiene, startMinutesFromMidnight: 10 * 60, durationMinutes: 30),
        ]
        let updated = BulkCategoryEditor.apply(category: .meal, to: blocks)
        XCTAssertTrue(updated.allSatisfy { $0.category == .meal })
    }

    func test_apply_emptyArrayIsNoOp() {
        let updated = BulkCategoryEditor.apply(category: .work, to: [])
        XCTAssertTrue(updated.isEmpty)
    }
}
