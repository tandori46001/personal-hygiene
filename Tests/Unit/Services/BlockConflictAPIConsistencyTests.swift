@testable import PersonalHygiene
import XCTest

/// Round-22 slice T1.5 — guards that `BlockConflictDetector.conflictingIDs`
/// (round-18 boolean API) and `BlockConflictOverlap.overlaps` (round-21
/// per-pair API) stay in sync. Every ID flagged by the detector must
/// participate in at least one overlap pair, and every overlap pair must
/// have both its endpoints flagged. Catches drift between the two APIs.
final class BlockConflictAPIConsistencyTests: XCTestCase {

    private func block(_ title: String, start: Int, duration: Int) -> Block {
        Block(
            title: title,
            category: .work,
            startMinutesFromMidnight: start,
            durationMinutes: duration
        )
    }

    func test_apis_agreeOnEmptyInput() {
        XCTAssertTrue(BlockConflictDetector.conflictingIDs(in: []).isEmpty)
        XCTAssertTrue(BlockConflictOverlap.overlaps(in: []).isEmpty)
    }

    func test_apis_agreeWhenNoConflict() {
        let blocks = [
            block("A", start: 9 * 60, duration: 30),
            block("B", start: 10 * 60, duration: 30),
        ]
        XCTAssertTrue(BlockConflictDetector.conflictingIDs(in: blocks).isEmpty)
        XCTAssertTrue(BlockConflictOverlap.overlaps(in: blocks).isEmpty)
    }

    func test_apis_agreeOnEveryConflictingID() {
        let blocks = [
            block("A", start: 9 * 60, duration: 120),
            block("B", start: 9 * 60 + 30, duration: 60),
            block("C", start: 10 * 60 + 30, duration: 60),
            block("D", start: 18 * 60, duration: 30),
        ]
        let flagged = BlockConflictDetector.conflictingIDs(in: blocks)
        let overlaps = BlockConflictOverlap.overlaps(in: blocks)

        var seenInOverlaps: Set<UUID> = []
        for overlap in overlaps {
            seenInOverlaps.insert(overlap.firstID)
            seenInOverlaps.insert(overlap.secondID)
        }

        XCTAssertEqual(flagged, seenInOverlaps, "boolean detector ↔ pair overlap APIs must agree on the conflict set")
    }

    func test_overlapPair_endpointsAreAlwaysInDetectorResult() {
        let blocks = [
            block("A", start: 9 * 60, duration: 60),
            block("B", start: 9 * 60 + 30, duration: 60),
        ]
        let flagged = BlockConflictDetector.conflictingIDs(in: blocks)
        for pair in BlockConflictOverlap.overlaps(in: blocks) {
            XCTAssertTrue(flagged.contains(pair.firstID))
            XCTAssertTrue(flagged.contains(pair.secondID))
        }
    }
}
