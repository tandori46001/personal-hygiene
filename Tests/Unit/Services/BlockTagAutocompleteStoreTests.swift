@testable import PersonalHygiene
import XCTest

final class BlockTagAutocompleteStoreTests: XCTestCase {

    private let suite = "tagAutocomplete-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_record_normalizesAndDedups() {
        BlockTagAutocompleteStore.record("Work", in: defaults)
        BlockTagAutocompleteStore.record("WORK", in: defaults)
        let stored = BlockTagAutocompleteStore.suggestions(in: defaults)
        XCTAssertEqual(stored, ["work"])
    }

    func test_suggestions_filtersByPrefix() {
        BlockTagAutocompleteStore.record("morning", in: defaults)
        BlockTagAutocompleteStore.record("evening", in: defaults)
        BlockTagAutocompleteStore.record("medical", in: defaults)
        let suggestions = BlockTagAutocompleteStore.suggestions(prefix: "m", in: defaults)
        XCTAssertTrue(suggestions.contains("medical"))
        XCTAssertTrue(suggestions.contains("morning"))
        XCTAssertFalse(suggestions.contains("evening"))
    }

    func test_capacity_capsAtFifty() {
        for idx in 0..<60 {
            BlockTagAutocompleteStore.record("tag-\(idx)", in: defaults)
        }
        let stored = BlockTagAutocompleteStore.suggestions(limit: 100, in: defaults)
        XCTAssertEqual(stored.count, 50)
    }

    func test_recordEmpty_isNoOp() {
        BlockTagAutocompleteStore.record("   ", in: defaults)
        XCTAssertTrue(BlockTagAutocompleteStore.suggestions(in: defaults).isEmpty)
    }
}
