@testable import PersonalHygiene
import XCTest

final class BlockTitleHistoryAutocompleteV2Tests: XCTestCase {

    private func entry(_ title: String, daysAgo: Int) -> BlockTitleHistoryAutocompleteV2.Suggestion {
        BlockTitleHistoryAutocompleteV2.Suggestion(
            title: title,
            lastUsed: Date().addingTimeInterval(-Double(daysAgo) * 86_400)
        )
    }

    func test_emptyQuery_returnsRecentFirst() {
        let entries = [
            entry("Reading", daysAgo: 5),
            entry("Take meds", daysAgo: 1),
            entry("Workout", daysAgo: 3),
        ]
        let suggestions = BlockTitleHistoryAutocompleteV2.suggest(history: entries, query: "")
        XCTAssertEqual(suggestions.first, "Take meds")
    }

    func test_prefixMatch_outranksContainsMatch() {
        let entries = [
            entry("My take on it", daysAgo: 1),  // contains "ta"
            entry("Take meds", daysAgo: 5),       // prefix "ta"
        ]
        let suggestions = BlockTitleHistoryAutocompleteV2.suggest(history: entries, query: "ta")
        XCTAssertEqual(suggestions.first, "Take meds")
    }

    func test_caseInsensitive() {
        let entries = [entry("Reading Time", daysAgo: 1)]
        let suggestions = BlockTitleHistoryAutocompleteV2.suggest(history: entries, query: "READ")
        XCTAssertEqual(suggestions.first, "Reading Time")
    }

    func test_limit_isHonored() {
        let entries = (0..<10).map { entry("Title-\($0)", daysAgo: $0) }
        let suggestions = BlockTitleHistoryAutocompleteV2.suggest(
            history: entries,
            query: "title",
            limit: 3
        )
        XCTAssertEqual(suggestions.count, 3)
    }
}
