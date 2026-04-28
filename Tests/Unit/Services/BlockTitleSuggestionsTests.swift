@testable import PersonalHygiene
import XCTest

/// Round-21 slice T1.4 — guards `BlockTitleSuggestions.recent` invariants:
/// distinct titles, most-recent-first ordering, configurable cap, category
/// filter. Round 20 introduced the helper without unit coverage; this closes
/// the gap before T4.24 wires the same store into TemplateListView search.
final class BlockTitleSuggestionsTests: XCTestCase {

    private func block(_ title: String, category: BlockCategory = .work, start: Int = 9 * 60) -> Block {
        Block(
            title: title,
            category: category,
            startMinutesFromMidnight: start,
            durationMinutes: 30
        )
    }

    private func template(_ name: String, blocks: [Block]) -> RoutineTemplate {
        RoutineTemplate(name: name, dayType: .weekday, blocks: blocks)
    }

    func test_recent_returnsDistinctTitles_inMostRecentFirstOrder() {
        let templates = [
            template("Old", blocks: [block("Standup"), block("Lunch", start: 12 * 60)]),
            template("New", blocks: [block("Code review", start: 14 * 60), block("Standup")]),
        ]
        let result = BlockTitleSuggestions.recent(in: templates, category: .work)
        // Walks templates reversed → "New" first; within that template walks
        // sortedBlocks reversed → latest-start-time first ("Code review").
        XCTAssertEqual(result.first, "Code review", "latest start time in newest template wins")
        XCTAssertEqual(Set(result), Set(["Standup", "Code review", "Lunch"]))
        XCTAssertEqual(result.count, 3, "duplicates collapsed")
    }

    func test_recent_filtersByCategory() {
        let templates = [
            template("Mixed", blocks: [
                block("Standup", category: .work),
                block("Brush", category: .hygiene),
                block("Dose", category: .medication),
            ])
        ]
        let work = BlockTitleSuggestions.recent(in: templates, category: .work)
        let hygiene = BlockTitleSuggestions.recent(in: templates, category: .hygiene)
        XCTAssertEqual(work, ["Standup"])
        XCTAssertEqual(hygiene, ["Brush"])
    }

    func test_recent_capsAtLimit() {
        let many = (0..<10).map { block("Title \($0)", start: 8 * 60 + $0 * 30) }
        let templates = [template("All", blocks: many)]
        let limited = BlockTitleSuggestions.recent(in: templates, category: .work, limit: 3)
        XCTAssertEqual(limited.count, 3)
    }

    func test_recent_skipsEmptyAndWhitespaceTitles() {
        let templates = [
            template("Edge", blocks: [
                block("   "),
                block(""),
                block("Real title"),
            ])
        ]
        let result = BlockTitleSuggestions.recent(in: templates, category: .work)
        XCTAssertEqual(result, ["Real title"])
    }

    func test_recent_returnsEmptyForUnusedCategory() {
        let templates = [template("Only work", blocks: [block("Standup", category: .work)])]
        XCTAssertTrue(BlockTitleSuggestions.recent(in: templates, category: .sleep).isEmpty)
    }
}
