@testable import PersonalHygiene
@preconcurrency import XCTest

final class BedtimePlanCheckTests: XCTestCase {

    private func block(_ title: String, start: Int, duration: Int = 30) -> Block {
        Block(title: title, category: .work, startMinutesFromMidnight: start, durationMinutes: duration)
    }

    func test_evaluate_emptyBlocksReturnsEmpty() {
        XCTAssertEqual(BedtimePlanCheck.evaluate(blocks: []), .empty)
    }

    func test_evaluate_readyForNonOverlappingBlocks() {
        let blocks = [block("A", start: 9 * 60), block("B", start: 10 * 60)]
        XCTAssertEqual(BedtimePlanCheck.evaluate(blocks: blocks), .ready)
    }

    func test_evaluate_conflictForOverlappingBlocks() {
        let blocks = [block("A", start: 9 * 60, duration: 60), block("B", start: 9 * 60 + 30)]
        XCTAssertEqual(BedtimePlanCheck.evaluate(blocks: blocks), .conflict)
    }
}
