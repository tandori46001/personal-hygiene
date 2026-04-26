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

    // MARK: - Block completions

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_markDone_persistsCompletionForCalendarDay() throws {
        let block = Block(title: "x", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        try repo.upsert(template)

        let now = date(year: 2026, month: 4, day: 25)
        try repo.markDone(block, on: now, calendar: gregorianUTC())

        XCTAssertTrue(try repo.isDone(block, on: now, calendar: gregorianUTC()))
        XCTAssertEqual(try repo.completions(on: now, calendar: gregorianUTC()).count, 1)
    }

    func test_markDone_isIdempotent() throws {
        let block = Block(title: "x", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        try repo.upsert(template)

        let now = date(year: 2026, month: 4, day: 25)
        try repo.markDone(block, on: now, calendar: gregorianUTC())
        try repo.markDone(block, on: now, calendar: gregorianUTC())

        XCTAssertEqual(try repo.completions(on: now, calendar: gregorianUTC()).count, 1)
    }

    func test_unmarkDone_removesCompletion() throws {
        let block = Block(title: "x", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        try repo.upsert(template)

        let now = date(year: 2026, month: 4, day: 25)
        try repo.markDone(block, on: now, calendar: gregorianUTC())
        try repo.unmarkDone(block, on: now, calendar: gregorianUTC())

        XCTAssertFalse(try repo.isDone(block, on: now, calendar: gregorianUTC()))
        XCTAssertTrue(try repo.completions(on: now, calendar: gregorianUTC()).isEmpty)
    }

    func test_isDone_isPerCalendarDay() throws {
        let block = Block(title: "x", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        try repo.upsert(template)

        let monday = date(year: 2026, month: 4, day: 25)
        let tuesday = date(year: 2026, month: 4, day: 26)
        try repo.markDone(block, on: monday, calendar: gregorianUTC())

        XCTAssertTrue(try repo.isDone(block, on: monday, calendar: gregorianUTC()))
        XCTAssertFalse(try repo.isDone(block, on: tuesday, calendar: gregorianUTC()))
    }
}
