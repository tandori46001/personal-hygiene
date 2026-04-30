@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-25 slice T1.8: the archive set survives a "fresh read" — set,
/// throw away the in-memory store reference, re-read, and confirm the
/// flag is still there. Guards against a regression where a struct-local
/// cache shadowed the UserDefaults read.
@MainActor
final class ArchivedTemplateFilterPersistenceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TemplateArchiveStore.clear()
    }

    override func tearDown() {
        TemplateArchiveStore.clear()
        super.tearDown()
    }

    func test_filter_followsToggleAcrossReads() {
        let alpha = RoutineTemplate(name: "Alpha", dayType: .weekday, blocks: [])
        let bravo = RoutineTemplate(name: "Bravo", dayType: .weekday, blocks: [])

        XCTAssertEqual(
            TemplateListView.filterTemplates([alpha, bravo], showingArchived: false).count,
            2
        )

        TemplateArchiveStore.setArchived(true, for: alpha.id)
        XCTAssertEqual(
            TemplateListView.filterTemplates([alpha, bravo], showingArchived: false).count,
            1
        )

        TemplateArchiveStore.setArchived(false, for: alpha.id)
        XCTAssertEqual(
            TemplateListView.filterTemplates([alpha, bravo], showingArchived: false).count,
            2
        )
    }

    func test_filter_showsArchivedWhenFlagOn() {
        let alpha = RoutineTemplate(name: "Alpha", dayType: .weekday, blocks: [])
        TemplateArchiveStore.setArchived(true, for: alpha.id)

        XCTAssertEqual(
            TemplateListView.filterTemplates([alpha], showingArchived: true).map(\.id),
            [alpha.id]
        )
        XCTAssertNotNil(TemplateListView.archivedBadgeText(for: alpha))
    }
}
