import XCTest

@testable import PersonalHygiene

final class NextBlockResolverTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: gregorianUTC(),
            timeZone: gregorianUTC().timeZone,
            year: 2026, month: 4, day: 25, hour: hour, minute: minute
        ).date!
    }

    private func makeTemplate(blocks: [Block]) -> RoutineTemplate {
        RoutineTemplate(name: "T", dayType: .weekday, blocks: blocks, isActive: true)
    }

    func test_returnsNilWhenNoTemplate() {
        XCTAssertNil(NextBlockResolver.resolve(in: nil, at: date(hour: 8, minute: 0), calendar: gregorianUTC()))
    }

    func test_returnsCurrentBlockWhenInProgress() {
        let block = Block(
            title: "Hygiene",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [block])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 7, minute: 15), calendar: gregorianUTC())
        XCTAssertEqual(result?.block.title, "Hygiene")
        XCTAssertEqual(result?.isCurrent, true)
    }

    func test_returnsNextUpcomingBlockOtherwise() {
        let earlier = Block(
            title: "Past",
            category: .hygiene,
            startMinutesFromMidnight: 6 * 60,
            durationMinutes: 30
        )
        let later = Block(
            title: "Future",
            category: .hygiene,
            startMinutesFromMidnight: 10 * 60,
            durationMinutes: 60
        )
        let template = makeTemplate(blocks: [earlier, later])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 8, minute: 0), calendar: gregorianUTC())
        XCTAssertEqual(result?.block.title, "Future")
        XCTAssertEqual(result?.isCurrent, false)
        XCTAssertEqual(result?.startMinutesFromMidnight, 10 * 60)
    }

    func test_returnsNilAfterAllBlocks() {
        let block = Block(
            title: "Done",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [block])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 22, minute: 0), calendar: gregorianUTC())
        XCTAssertNil(result)
    }
}
