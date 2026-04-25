import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class SwiftDataRoutineRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var repo: SwiftDataRoutineRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        context = container.mainContext
        repo = SwiftDataRoutineRepository(context: context)
    }

    override func tearDown() async throws {
        repo = nil
        context = nil
        container = nil
        try await super.tearDown()
    }

    func test_upsertTemplate_persistsAndAllTemplatesReturnsIt() throws {
        let template = RoutineTemplate(name: "Weekday", dayType: .weekday)

        try repo.upsert(template)

        XCTAssertEqual(try repo.allTemplates().count, 1)
        XCTAssertEqual(try repo.allTemplates().first?.name, "Weekday")
    }

    func test_setActive_marksOnlyOneTemplatePerDayTypeActive() throws {
        let templateA = RoutineTemplate(name: "A", dayType: .weekday)
        let templateB = RoutineTemplate(name: "B", dayType: .weekday)
        try repo.upsert(templateA)
        try repo.upsert(templateB)

        try repo.setActive(templateA, for: .weekday)
        XCTAssertEqual(try repo.activeTemplate(for: .weekday)?.name, "A")

        try repo.setActive(templateB, for: .weekday)
        XCTAssertEqual(try repo.activeTemplate(for: .weekday)?.name, "B")
    }

    func test_upsertBlock_addsBlockToTemplate() throws {
        let template = RoutineTemplate(name: "T", dayType: .weekday)
        try repo.upsert(template)

        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        try repo.upsert(block, in: template)

        XCTAssertEqual(template.blocks.count, 1)
        XCTAssertEqual(template.blocks.first?.title, "Aseo")
    }

    func test_deleteTemplate_removesItAndCascadesBlocks() throws {
        let block = Block(
            title: "X",
            category: .meal,
            startMinutesFromMidnight: 0,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        try repo.upsert(template)

        try repo.delete(template)

        XCTAssertTrue(try repo.allTemplates().isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Block>()).isEmpty)
    }
}
