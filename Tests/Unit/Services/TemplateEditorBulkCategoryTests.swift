@testable import PersonalHygiene
import SwiftData
@preconcurrency import XCTest

@MainActor
final class TemplateEditorBulkCategoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataRoutineRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        repository = SwiftDataRoutineRepository(context: container.mainContext)
    }

    override func tearDown() async throws {
        repository = nil
        container = nil
        try await super.tearDown()
    }

    private func block(_ title: String, category: BlockCategory = .work, start: Int = 9 * 60) -> Block {
        Block(title: title, category: category, startMinutesFromMidnight: start, durationMinutes: 30)
    }

    func test_applyBulkCategory_changesEverySelectedBlock() throws {
        let alpha = block("A", category: .work, start: 9 * 60)
        let bravo = block("B", category: .hygiene, start: 10 * 60)
        let charlie = block("C", category: .meal, start: 11 * 60)
        let template = RoutineTemplate(
            name: "T",
            dayType: .weekday,
            blocks: [alpha, bravo, charlie],
            isActive: true
        )
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)

        try viewModel.applyBulkCategory(ids: [alpha.id, charlie.id], category: .sport)

        let updated = viewModel.sortedBlocks
        XCTAssertEqual(updated[0].category, .sport, "alpha changed")
        XCTAssertEqual(updated[1].category, .hygiene, "bravo untouched (not selected)")
        XCTAssertEqual(updated[2].category, .sport, "charlie changed")
    }

    func test_applyBulkCategory_noOpForEmptySelection() throws {
        let alpha = block("A", category: .work)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [alpha])
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)

        try viewModel.applyBulkCategory(ids: [], category: .sport)
        XCTAssertEqual(viewModel.sortedBlocks.first?.category, .work)
    }
}
