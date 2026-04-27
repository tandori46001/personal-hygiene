import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class TodayViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var repo: SwiftDataRoutineRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        repo = SwiftDataRoutineRepository(context: container.mainContext)
    }

    override func tearDown() async throws {
        repo = nil
        container = nil
        try await super.tearDown()
    }

    private func calendarFixedToDay(weekday: Int) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(weekday: Int, hour: Int = 8, minute: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        // 2026-01-04 was a Sunday → weekday 1. Build forward.
        let baseSunday = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 1, day: 4, hour: hour, minute: minute
        ).date!
        let offset = (weekday - 1 + 7) % 7
        return cal.date(byAdding: .day, value: offset, to: baseSunday)!
    }

    func test_dayType_weekendOnSundayAndSaturday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(TodayViewModel.dayType(for: date(weekday: 1), in: cal), .weekend)
        XCTAssertEqual(TodayViewModel.dayType(for: date(weekday: 7), in: cal), .weekend)
    }

    func test_dayType_weekdayOnMondayThroughFriday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        for weekday in 2...6 {
            XCTAssertEqual(TodayViewModel.dayType(for: date(weekday: weekday), in: cal), .weekday)
        }
    }

    func test_reload_pullsActiveTemplateForToday() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let template = RoutineTemplate(name: "Weekday", dayType: .weekday, isActive: true)
        try repo.upsert(template)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        vm.reload(now: date(weekday: 3, hour: 8))

        XCTAssertEqual(vm.activeTemplate?.name, "Weekday")
        XCTAssertEqual(vm.todaysDayType, .weekday)
    }

    func test_currentBlock_returnsBlockContainingNow() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let block = Block(
            title: "Work",
            category: .work,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 8 * 60
        )
        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [block],
            isActive: true
        )
        try repo.upsert(template)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        vm.reload(now: date(weekday: 3, hour: 12))

        XCTAssertEqual(vm.currentBlock(at: date(weekday: 3, hour: 12))?.title, "Work")
    }

    func test_nextBlock_returnsFirstBlockAfterNow() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let blocks = [
            Block(title: "Hygiene", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30),
            Block(title: "Lunch", category: .meal, startMinutesFromMidnight: 13 * 60, durationMinutes: 60),
        ]
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: blocks, isActive: true)
        try repo.upsert(template)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        vm.reload(now: date(weekday: 3, hour: 8))

        XCTAssertEqual(vm.nextBlock(after: date(weekday: 3, hour: 8))?.title, "Lunch")
    }

    func test_toggleDone_marksAndUnmarksOnSameBlock() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let block = Block(
            title: "Hygiene",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block], isActive: true)
        try repo.upsert(template)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        let now = date(weekday: 3, hour: 9)
        vm.reload(now: now)

        XCTAssertFalse(vm.isDone(block))
        vm.toggleDone(block, now: now)
        XCTAssertTrue(vm.isDone(block))
        XCTAssertEqual(vm.doneCount, 1)

        vm.toggleDone(block, now: now)
        XCTAssertFalse(vm.isDone(block))
        XCTAssertEqual(vm.doneCount, 0)
    }

    func test_nextUpcoming_picksEarliestFutureTrip() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = date(weekday: 3, hour: 10)
        let past = Trip(
            name: "Past",
            startDate: cal.date(byAdding: .day, value: -10, to: now)!,
            endDate: cal.date(byAdding: .day, value: -3, to: now)!,
            destinationName: "X"
        )
        let nearFuture = Trip(
            name: "Near",
            startDate: cal.date(byAdding: .day, value: 5, to: now)!,
            endDate: cal.date(byAdding: .day, value: 12, to: now)!,
            destinationName: "Y"
        )
        let farFuture = Trip(
            name: "Far",
            startDate: cal.date(byAdding: .day, value: 60, to: now)!,
            endDate: cal.date(byAdding: .day, value: 70, to: now)!,
            destinationName: "Z"
        )
        let result = TodayViewModel.nextUpcoming(
            trips: [farFuture, past, nearFuture],
            now: now,
            calendar: cal
        )
        XCTAssertEqual(result?.name, "Near")
    }

    func test_toggleSkippedToday_persistsThroughSkipStore() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let block = Block(
            title: "Hygiene",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block], isActive: true)
        try repo.upsert(template)

        let skipStore = InMemoryBlockSkipStore()
        let vm = TodayViewModel(repository: repo, skipStore: skipStore, calendar: cal)
        let now = date(weekday: 3, hour: 9)

        XCTAssertFalse(vm.isSkipped(block, now: now))
        vm.toggleSkippedToday(block, now: now)
        XCTAssertTrue(vm.isSkipped(block, now: now))
        vm.toggleSkippedToday(block, now: now)
        XCTAssertFalse(vm.isSkipped(block, now: now))
    }

    // MARK: - Skip-rest-of-today cascade (round 9 slice 18)

    func test_skipRestOfToday_marksAllBlocksAtOrAfterCutoffAsSkipped() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let early = Block(
            title: "Early",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let mid = Block(
            title: "Mid",
            category: .hygiene,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 30
        )
        let late = Block(
            title: "Late",
            category: .hygiene,
            startMinutesFromMidnight: 18 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(
            name: "T",
            dayType: .weekday,
            blocks: [early, mid, late],
            isActive: true
        )
        try repo.upsert(template)

        let skipStore = InMemoryBlockSkipStore()
        let vm = TodayViewModel(repository: repo, skipStore: skipStore, calendar: cal)
        let now = date(weekday: 3, hour: 8)
        vm.reload(now: now)

        vm.skipRestOfToday(from: mid, now: now)

        XCTAssertFalse(vm.isSkipped(early, now: now), "blocks before cutoff stay un-skipped")
        XCTAssertTrue(vm.isSkipped(mid, now: now), "cutoff block itself is skipped")
        XCTAssertTrue(vm.isSkipped(late, now: now), "blocks after cutoff are skipped")
    }

    func test_skipRestOfToday_isNoOpWithoutSkipStore() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let block = Block(
            title: "B",
            category: .hygiene,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block], isActive: true)
        try repo.upsert(template)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        let now = date(weekday: 3, hour: 8)
        vm.reload(now: now)

        // Without a skip store the call must not crash and must leave state alone.
        vm.skipRestOfToday(from: block, now: now)
        XCTAssertFalse(vm.isSkipped(block, now: now))
    }

    func test_reload_rehydratesCompletionsForToday() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let block = Block(
            title: "Hygiene",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [block], isActive: true)
        try repo.upsert(template)
        let now = date(weekday: 3, hour: 9)
        try repo.markDone(block, on: now, calendar: cal)

        let vm = TodayViewModel(repository: repo, calendar: cal)
        vm.reload(now: now)

        XCTAssertTrue(vm.isDone(block))
    }
}
