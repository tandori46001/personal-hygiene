@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class TemplateEditorCascadeShiftTests: XCTestCase {

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

    private func block(_ title: String, start: Int, duration: Int = 30) -> Block {
        Block(title: title, category: .work, startMinutesFromMidnight: start, durationMinutes: duration)
    }

    func test_cascadeShift_movesEveryBlockByDelta() throws {
        let template = RoutineTemplate(
            name: "T",
            dayType: .weekday,
            blocks: [block("A", start: 9 * 60), block("B", start: 12 * 60)]
        )
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)

        try viewModel.cascadeShift(byMinutes: 15)

        let updated = viewModel.sortedBlocks
        XCTAssertEqual(updated[0].startMinutesFromMidnight, 9 * 60 + 15)
        XCTAssertEqual(updated[1].startMinutesFromMidnight, 12 * 60 + 15)
    }

    func test_cascadeShift_isNoOpForZeroDelta() throws {
        let template = RoutineTemplate(
            name: "T",
            dayType: .weekday,
            blocks: [block("A", start: 9 * 60)]
        )
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)
        try viewModel.cascadeShift(byMinutes: 0)
        XCTAssertEqual(viewModel.sortedBlocks.first?.startMinutesFromMidnight, 9 * 60)
    }

    func test_cascadeShift_clampsToDayBoundary() throws {
        let template = RoutineTemplate(
            name: "T",
            dayType: .weekday,
            blocks: [block("Late", start: 23 * 60)]
        )
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)
        try viewModel.cascadeShift(byMinutes: 120)
        XCTAssertEqual(viewModel.sortedBlocks.first?.startMinutesFromMidnight, 24 * 60 - 1)
    }

    func test_importCSV_insertsParsedBlocks() throws {
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [])
        try repository.upsert(template)
        let viewModel = TemplateEditorViewModel(template: template, repository: repository)

        let csv = """
        title,category,startMinutes,durationMinutes
        Standup,work,540,15
        Brush,hygiene,420,10
        """
        let warnings = try viewModel.importCSV(csv)
        XCTAssertTrue(warnings.isEmpty)
        XCTAssertEqual(viewModel.sortedBlocks.count, 2)
    }
}
