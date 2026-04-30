@testable import PersonalHygiene
@preconcurrency import XCTest

final class BirthdayIdeaStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "test.bday-idea-\(UUID().uuidString)")!
    }

    func test_idea_nilByDefault() {
        XCTAssertNil(BirthdayIdeaStore.idea(for: "abc", defaults: defaults))
    }

    func test_set_andRead() {
        BirthdayIdeaStore.set("Bluetooth speaker", for: "abc", in: defaults)
        XCTAssertEqual(BirthdayIdeaStore.idea(for: "abc", defaults: defaults), "Bluetooth speaker")
    }

    func test_setNil_removes() {
        BirthdayIdeaStore.set("idea", for: "id", in: defaults)
        BirthdayIdeaStore.set(nil, for: "id", in: defaults)
        XCTAssertNil(BirthdayIdeaStore.idea(for: "id", defaults: defaults))
    }

    func test_setEmpty_removes() {
        BirthdayIdeaStore.set("idea", for: "id", in: defaults)
        BirthdayIdeaStore.set("   ", for: "id", in: defaults)
        XCTAssertNil(BirthdayIdeaStore.idea(for: "id", defaults: defaults))
    }
}
