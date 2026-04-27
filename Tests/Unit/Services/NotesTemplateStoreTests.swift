@testable import PersonalHygiene
import XCTest

final class NotesTemplateStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.notes-templates-\(UUID().uuidString)")!
    }

    func test_entries_emptyByDefault() {
        XCTAssertTrue(NotesTemplateStore.entries(defaults: defaults).isEmpty)
    }

    func test_add_persists() {
        NotesTemplateStore.add(title: "Flight", body: "Confirmation: ABC123", in: defaults)
        let entries = NotesTemplateStore.entries(defaults: defaults)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "Flight")
    }

    func test_add_emptyIgnored() {
        NotesTemplateStore.add(title: "", body: "body", in: defaults)
        NotesTemplateStore.add(title: "title", body: "  ", in: defaults)
        XCTAssertTrue(NotesTemplateStore.entries(defaults: defaults).isEmpty)
    }

    func test_remove_byID() {
        NotesTemplateStore.add(title: "A", body: "1", in: defaults)
        NotesTemplateStore.add(title: "B", body: "2", in: defaults)
        let toRemove = NotesTemplateStore.entries(defaults: defaults)[0]
        NotesTemplateStore.remove(id: toRemove.id, in: defaults)
        let remaining = NotesTemplateStore.entries(defaults: defaults)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.title, "B")
    }
}
