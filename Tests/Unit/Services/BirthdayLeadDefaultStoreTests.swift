@testable import PersonalHygiene
import XCTest

final class BirthdayLeadDefaultStoreTests: XCTestCase {

    private let suite = "leadDefaultTests-\(UUID().uuidString)"
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

    func test_effectiveDefault_fallsBackToLegacyConstant() {
        XCTAssertEqual(BirthdayLeadDefaultStore.effectiveDefault(in: defaults),
                       UserDefaultsBirthdayLeadStore.defaultLeadDays)
    }

    func test_setDefault_persistsAndClamps() {
        BirthdayLeadDefaultStore.setDefault(99, in: defaults)
        XCTAssertEqual(BirthdayLeadDefaultStore.effectiveDefault(in: defaults), 60)
        BirthdayLeadDefaultStore.setDefault(-5, in: defaults)
        XCTAssertEqual(BirthdayLeadDefaultStore.effectiveDefault(in: defaults), 0)
        BirthdayLeadDefaultStore.setDefault(3, in: defaults)
        XCTAssertEqual(BirthdayLeadDefaultStore.effectiveDefault(in: defaults), 3)
    }

    func test_clear_revertsToLegacyConstant() {
        BirthdayLeadDefaultStore.setDefault(14, in: defaults)
        BirthdayLeadDefaultStore.clear(in: defaults)
        XCTAssertEqual(BirthdayLeadDefaultStore.effectiveDefault(in: defaults),
                       UserDefaultsBirthdayLeadStore.defaultLeadDays)
    }
}
