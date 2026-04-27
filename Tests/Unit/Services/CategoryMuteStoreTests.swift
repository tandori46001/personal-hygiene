@testable import PersonalHygiene
import XCTest

final class CategoryMuteStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.mute-\(UUID().uuidString)")!
    }

    func test_isMuted_defaultFalse() {
        for cat in NotificationCategoryMuteStore.Category.allCases {
            XCTAssertFalse(NotificationCategoryMuteStore.isMuted(cat, defaults: defaults))
        }
    }

    func test_setMuted_perCategory() {
        NotificationCategoryMuteStore.setMuted(true, for: .hydration, in: defaults)
        XCTAssertTrue(NotificationCategoryMuteStore.isMuted(.hydration, defaults: defaults))
        XCTAssertFalse(NotificationCategoryMuteStore.isMuted(.medication, defaults: defaults))
    }

    func test_clearAll_resetsEverything() {
        for cat in NotificationCategoryMuteStore.Category.allCases {
            NotificationCategoryMuteStore.setMuted(true, for: cat, in: defaults)
        }
        NotificationCategoryMuteStore.clearAll(in: defaults)
        for cat in NotificationCategoryMuteStore.Category.allCases {
            XCTAssertFalse(NotificationCategoryMuteStore.isMuted(cat, defaults: defaults))
        }
    }
}
