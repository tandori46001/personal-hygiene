@testable import PersonalHygiene
@preconcurrency import XCTest

final class TemplateArchiveStoreTests: XCTestCase {

    private let suite = "templateArchiveTests-\(UUID().uuidString)"
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

    func test_setArchived_persistsAndRetrieves() {
        let id = UUID()
        XCTAssertFalse(TemplateArchiveStore.isArchived(id, in: defaults))
        TemplateArchiveStore.setArchived(true, for: id, in: defaults)
        XCTAssertTrue(TemplateArchiveStore.isArchived(id, in: defaults))
    }

    func test_unarchive_removesEntry() {
        let id = UUID()
        TemplateArchiveStore.setArchived(true, for: id, in: defaults)
        TemplateArchiveStore.setArchived(false, for: id, in: defaults)
        XCTAssertFalse(TemplateArchiveStore.isArchived(id, in: defaults))
    }

    func test_archivedIDs_returnsAllArchived() {
        let id1 = UUID()
        let id2 = UUID()
        TemplateArchiveStore.setArchived(true, for: id1, in: defaults)
        TemplateArchiveStore.setArchived(true, for: id2, in: defaults)
        let archived = TemplateArchiveStore.archivedIDs(in: defaults)
        XCTAssertEqual(archived.count, 2)
        XCTAssertTrue(archived.contains(id1))
        XCTAssertTrue(archived.contains(id2))
    }
}
