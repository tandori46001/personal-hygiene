@testable import PersonalHygiene
@preconcurrency import XCTest

final class FocusCategoryMuteMirrorTests: XCTestCase {

    private let primarySuite = "muteMirrorTests-primary-\(UUID().uuidString)"
    private let mirrorSuite = "muteMirrorTests-mirror-\(UUID().uuidString)"
    private var primary: UserDefaults!
    private var mirror: UserDefaults!

    override func setUp() {
        super.setUp()
        primary = UserDefaults(suiteName: primarySuite)!
        mirror = UserDefaults(suiteName: mirrorSuite)!
        primary.removePersistentDomain(forName: primarySuite)
        mirror.removePersistentDomain(forName: mirrorSuite)
    }

    override func tearDown() {
        primary.removePersistentDomain(forName: primarySuite)
        mirror.removePersistentDomain(forName: mirrorSuite)
        primary = nil
        mirror = nil
        super.tearDown()
    }

    func test_mirror_copiesActiveCategoriesIntoSharedSuite() {
        NotificationCategoryMuteStore.setMuted(true, for: .hydration, in: primary)
        NotificationCategoryMuteStore.setMuted(true, for: .bedtime, in: primary)

        FocusCategoryMuteMirror.mirror(from: primary, to: mirror)

        let mirrored = FocusCategoryMuteMirror.mirroredCategories(in: mirror)
        XCTAssertTrue(mirrored.contains(.hydration))
        XCTAssertTrue(mirrored.contains(.bedtime))
        XCTAssertFalse(mirrored.contains(.medication))
    }

    func test_mirror_overwritesPriorMirror() {
        NotificationCategoryMuteStore.setMuted(true, for: .hydration, in: primary)
        FocusCategoryMuteMirror.mirror(from: primary, to: mirror)

        NotificationCategoryMuteStore.setMuted(false, for: .hydration, in: primary)
        FocusCategoryMuteMirror.mirror(from: primary, to: mirror)

        XCTAssertTrue(FocusCategoryMuteMirror.mirroredCategories(in: mirror).isEmpty)
    }
}
