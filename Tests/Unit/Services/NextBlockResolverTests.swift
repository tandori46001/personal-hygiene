@preconcurrency import XCTest

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

    // MARK: - Edge cases (session 6)

    func test_emptyTemplate_returnsNil() {
        let template = makeTemplate(blocks: [])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 8, minute: 0), calendar: gregorianUTC())
        XCTAssertNil(result)
    }

    func test_exactlyAtBlockStart_isCurrent() {
        let block = Block(
            title: "On the dot",
            category: .hygiene,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [block])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 8, minute: 0), calendar: gregorianUTC())
        XCTAssertEqual(result?.isCurrent, true)
        XCTAssertEqual(result?.block.title, "On the dot")
    }

    func test_exactlyAtBlockEnd_picksNextNotEnded() {
        let earlier = Block(
            title: "Ending",
            category: .hygiene,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 30
        )
        let later = Block(
            title: "Coming",
            category: .work,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 60
        )
        let template = makeTemplate(blocks: [earlier, later])
        // 08:30 is exactly the end of "Ending" → that block has ended (end is exclusive),
        // so the resolver returns the next upcoming one.
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 8, minute: 30), calendar: gregorianUTC())
        XCTAssertEqual(result?.block.title, "Coming")
        XCTAssertEqual(result?.isCurrent, false)
    }

    func test_doesNotWrapAroundMidnight() {
        // The resolver intentionally does not return tomorrow's first block when
        // today's last has ended — the widget renders empty in that window.
        let block = Block(
            title: "Last",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [block])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 23, minute: 59), calendar: gregorianUTC())
        XCTAssertNil(result)
    }

    func test_pickFirstBlockBeforeAnyHasStarted() {
        let block = Block(
            title: "First",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [block])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 1, minute: 0), calendar: gregorianUTC())
        XCTAssertEqual(result?.block.title, "First")
        XCTAssertEqual(result?.isCurrent, false)
    }

    func test_overlappingBlocks_picksFirstSorted() {
        // Two blocks overlap at 08:15. The resolver picks the first one in
        // sorted order (start asc) — defensive coverage for malformed data.
        let early = Block(
            title: "Early",
            category: .hygiene,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 30
        )
        let lateOverlap = Block(
            title: "Overlap",
            category: .work,
            startMinutesFromMidnight: 8 * 60 + 15,
            durationMinutes: 30
        )
        let template = makeTemplate(blocks: [early, lateOverlap])
        let result = NextBlockResolver.resolve(in: template, at: date(hour: 8, minute: 20), calendar: gregorianUTC())
        XCTAssertEqual(result?.block.title, "Early")
    }
}
