import XCTest
@testable import PersonalHygiene

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

    func test_initWithDefaults_setsVersionToOne() {
        let template = RoutineTemplate(name: "Test", dayType: .weekend)
        XCTAssertEqual(template.version, 1)
        XCTAssertTrue(template.blocks.isEmpty)
    }
}
