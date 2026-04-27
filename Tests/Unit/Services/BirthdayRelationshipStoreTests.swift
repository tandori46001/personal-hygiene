@testable import PersonalHygiene
import XCTest

final class BirthdayRelationshipStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "test.bday-rel-\(UUID().uuidString)")!
    }

    func test_relationship_otherByDefault() {
        XCTAssertEqual(BirthdayRelationshipStore.relationship(for: "abc", defaults: defaults), .other)
    }

    func test_set_andRead() {
        BirthdayRelationshipStore.set(.family, for: "abc", in: defaults)
        XCTAssertEqual(BirthdayRelationshipStore.relationship(for: "abc", defaults: defaults), .family)
    }

    func test_setOther_removes() {
        BirthdayRelationshipStore.set(.family, for: "abc", in: defaults)
        BirthdayRelationshipStore.set(.other, for: "abc", in: defaults)
        XCTAssertEqual(BirthdayRelationshipStore.relationship(for: "abc", defaults: defaults), .other)
        XCTAssertTrue(BirthdayRelationshipStore.dictionary(defaults: defaults).isEmpty)
    }
}
