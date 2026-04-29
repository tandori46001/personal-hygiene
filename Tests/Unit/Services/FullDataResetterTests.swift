@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class FullDataResetterTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    func test_resetEverything_clearsTemplatesAndCompletions() throws {
        let context = container.mainContext
        let template = RoutineTemplate(
            name: "T", dayType: .weekday,
            blocks: [Block(title: "B", category: .work, startMinutesFromMidnight: 540, durationMinutes: 30)]
        )
        context.insert(template)
        try context.save()

        XCTAssertFalse(try context.fetch(FetchDescriptor<RoutineTemplate>()).isEmpty)

        try FullDataResetter.resetEverything(in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineTemplate>()).isEmpty)
    }

    func test_resetEverything_clearsArchiveFlags() throws {
        let id = UUID()
        TemplateArchiveStore.setArchived(true, for: id)
        XCTAssertTrue(TemplateArchiveStore.isArchived(id))

        try FullDataResetter.resetEverything(in: container.mainContext)

        XCTAssertFalse(TemplateArchiveStore.isArchived(id))
    }

    func test_resetEverything_clearsMoodLog() throws {
        MoodLogStore.record(.great, now: Date())
        XCTAssertFalse(MoodLogStore.entries().isEmpty)

        try FullDataResetter.resetEverything(in: container.mainContext)

        XCTAssertTrue(MoodLogStore.entries().isEmpty)
    }
}
