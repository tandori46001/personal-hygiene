@testable import PersonalHygiene
@preconcurrency import XCTest

final class BlockConflictDetectorTests: XCTestCase {

    private func block(start: Int, duration: Int) -> Block {
        Block(
            title: "B",
            category: .hygiene,
            startMinutesFromMidnight: start,
            durationMinutes: duration
        )
    }

    func test_emptyAndSingleBlock_haveNoConflicts() {
        XCTAssertTrue(BlockConflictDetector.conflictingIDs(in: []).isEmpty)
        XCTAssertTrue(BlockConflictDetector.conflictingIDs(in: [block(start: 9 * 60, duration: 30)]).isEmpty)
    }

    func test_touchingBoundaries_doNotConflict() {
        let first = block(start: 9 * 60, duration: 30)   // 09:00–09:30
        let second = block(start: 9 * 60 + 30, duration: 30) // 09:30–10:00
        XCTAssertTrue(BlockConflictDetector.conflictingIDs(in: [first, second]).isEmpty)
    }

    func test_overlappingPair_flagsBothIDs() {
        let first = block(start: 9 * 60, duration: 60)   // 09:00–10:00
        let second = block(start: 9 * 60 + 30, duration: 30) // 09:30–10:00
        let conflicts = BlockConflictDetector.conflictingIDs(in: [first, second])
        XCTAssertEqual(conflicts, Set([first.id, second.id]))
    }

    func test_threewayOverlap_flagsAllInvolved() {
        let early = block(start: 8 * 60, duration: 90)       // 08:00–09:30
        let middle = block(start: 9 * 60, duration: 30)       // 09:00–09:30 (inside early)
        let later = block(start: 11 * 60, duration: 30)       // disjoint
        let conflicts = BlockConflictDetector.conflictingIDs(in: [early, middle, later])
        XCTAssertEqual(conflicts, Set([early.id, middle.id]))
        XCTAssertFalse(conflicts.contains(later.id))
    }
}
