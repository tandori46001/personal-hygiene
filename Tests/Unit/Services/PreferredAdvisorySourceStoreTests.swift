import XCTest

@testable import PersonalHygiene

final class PreferredAdvisorySourceStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-pref-adv-\(UUID().uuidString)")!
    }

    override func tearDown() {
        defaults.removeObject(forKey: PreferredAdvisorySourceStore.key)
        defaults = nil
        super.tearDown()
    }

    func test_defaultIsExteriores() {
        XCTAssertEqual(PreferredAdvisorySourceStore.preferred(defaults: defaults), .exteriores)
    }

    func test_setAndReadRoundTrip() {
        PreferredAdvisorySourceStore.set(.canada, in: defaults)
        XCTAssertEqual(PreferredAdvisorySourceStore.preferred(defaults: defaults), .canada)
    }

    func test_invalidStoredValueFallsBackToDefault() {
        defaults.set("not-a-real-source", forKey: PreferredAdvisorySourceStore.key)
        XCTAssertEqual(PreferredAdvisorySourceStore.preferred(defaults: defaults), .exteriores)
    }

    func test_reorder_movesPreferredToFront() {
        let svc = MultiSourceAdvisoryService.standard()
        let original = svc.advisories(forDestination: "Spain")
        let reordered = PreferredAdvisorySourceStore.reorder(original, preferred: .ukFCDO)
        XCTAssertEqual(reordered.first?.source, "gov.uk · FCDO")
        XCTAssertEqual(reordered.count, original.count)
        XCTAssertEqual(Set(reordered.map(\.source)), Set(original.map(\.source)))
    }

    func test_reorder_noopWhenPreferredMissing() {
        let only = MultiSourceAdvisoryService(upstreams: [ExterioresAdvisoryService()])
            .advisories(forDestination: "Spain")
        let reordered = PreferredAdvisorySourceStore.reorder(only, preferred: .ukFCDO)
        XCTAssertEqual(reordered.map(\.source), only.map(\.source))
    }
}
