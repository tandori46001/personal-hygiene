@testable import PersonalHygiene
import XCTest

@MainActor
final class TemplateListFilterTests: XCTestCase {

    private func template(name: String) -> RoutineTemplate {
        RoutineTemplate(name: name, dayType: .weekday, blocks: [])
    }

    override func setUp() {
        super.setUp()
        TemplateArchiveStore.clear()
    }

    override func tearDown() {
        TemplateArchiveStore.clear()
        super.tearDown()
    }

    func test_filter_excludesArchivedWhenHidingFlag() {
        let alpha = template(name: "Alpha")
        let bravo = template(name: "Bravo")
        TemplateArchiveStore.setArchived(true, for: bravo.id)

        let filtered = TemplateListView.filterTemplates([alpha, bravo], showingArchived: false)
        XCTAssertEqual(filtered.map(\.id), [alpha.id])
    }

    func test_filter_includesArchivedWhenShowing() {
        let alpha = template(name: "Alpha")
        let bravo = template(name: "Bravo")
        TemplateArchiveStore.setArchived(true, for: bravo.id)

        let filtered = TemplateListView.filterTemplates([alpha, bravo], showingArchived: true)
        XCTAssertEqual(filtered.count, 2)
    }

    func test_archivedBadgeText_emojiForArchivedRow() {
        let alpha = template(name: "Alpha")
        TemplateArchiveStore.setArchived(true, for: alpha.id)
        XCTAssertEqual(TemplateListView.archivedBadgeText(for: alpha), "📁")
    }
}
