import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class RoutineTemplateTests: XCTestCase {

    func test_sortedBlocks_returnsBlocksInChronologicalOrder() {
        let earlyBlock = Block(
            title: "Early",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let lateBlock = Block(
            title: "Late",
            category: .meal,
            startMinutesFromMidnight: 12 * 60,
            durationMinutes: 60
        )
        let middleBlock = Block(
            title: "Middle",
            category: .work,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 60
        )

        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [lateBlock, earlyBlock, middleBlock]
        )

        let sorted = template.sortedBlocks
        XCTAssertEqual(sorted.map(\.title), ["Early", "Middle", "Late"])
    }

    func test_initWithDefaults_setsVersionToOneAndInactive() {
        let template = RoutineTemplate(name: "Test", dayType: .weekend)
        XCTAssertEqual(template.version, 1)
        XCTAssertFalse(template.isActive)
        XCTAssertTrue(template.blocks.isEmpty)
    }

    func test_persistAndFetch_preservesRelationship() throws {
        let container = try AppModelContainer.makeInMemory()
        let context = container.mainContext

        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [block],
            isActive: true
        )
        context.insert(template)
        try context.save()

        let fetchedTemplates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        XCTAssertEqual(fetchedTemplates.count, 1)
        XCTAssertEqual(fetchedTemplates.first?.blocks.count, 1)
        XCTAssertEqual(fetchedTemplates.first?.blocks.first?.title, "Aseo")
        XCTAssertEqual(fetchedTemplates.first?.blocks.first?.template?.id, template.id)
    }

    func test_cascadeDelete_removesChildBlocks() throws {
        let container = try AppModelContainer.makeInMemory()
        let context = container.mainContext

        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block])
        context.insert(template)
        try context.save()

        context.delete(template)
        try context.save()

        let remainingBlocks = try context.fetch(FetchDescriptor<Block>())
        XCTAssertTrue(remainingBlocks.isEmpty)
    }
}
