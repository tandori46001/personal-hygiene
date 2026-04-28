@testable import PersonalHygiene
import XCTest

final class BlockConflictOverlapTests: XCTestCase {

    private func block(_ title: String, start: Int, duration: Int) -> Block {
        Block(title: title, category: .work, startMinutesFromMidnight: start, durationMinutes: duration)
    }

    func test_overlaps_emptyForNonOverlappingBlocks() {
        let blocks = [
            block("A", start: 9 * 60, duration: 30),
            block("B", start: 10 * 60, duration: 30),
        ]
        XCTAssertTrue(BlockConflictOverlap.overlaps(in: blocks).isEmpty)
    }

    func test_overlaps_detectsTwoMinuteSpanWhenBlocksTouchInside() {
        let early = block("A", start: 9 * 60, duration: 60)
        let late = block("B", start: 9 * 60 + 30, duration: 60)
        let overlaps = BlockConflictOverlap.overlaps(in: [early, late])
        XCTAssertEqual(overlaps.count, 1)
        XCTAssertEqual(overlaps.first?.overlapMinutes, 30)
    }

    func test_overlaps_handlesMultiPairOverlap() {
        let alpha = block("A", start: 9 * 60, duration: 120)
        let bravo = block("B", start: 9 * 60 + 30, duration: 60)
        let charlie = block("C", start: 10 * 60, duration: 60)
        let overlaps = BlockConflictOverlap.overlaps(in: [alpha, bravo, charlie])
        XCTAssertEqual(overlaps.count, 3, "A↔B, A↔C, B↔C")
    }

    func test_overlaps_summaryContainsBothTitles() throws {
        let standup = block("Standup", start: 9 * 60, duration: 60)
        let review = block("Code review", start: 9 * 60 + 30, duration: 60)
        let overlap = try XCTUnwrap(BlockConflictOverlap.overlaps(in: [standup, review]).first)
        let summary = BlockConflictOverlap.summary(
            for: overlap,
            titleByID: [standup.id: standup.title, review.id: review.title]
        )
        XCTAssertTrue(summary.contains("Standup"))
        XCTAssertTrue(summary.contains("Code review"))
        XCTAssertTrue(summary.contains("30"))
    }
}
