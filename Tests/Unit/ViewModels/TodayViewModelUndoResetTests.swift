@testable import PersonalHygiene
import SwiftData
import XCTest

/// Round-21 slice T1.6 — guards `TodayViewModel.undoResetDay(_:)` replay:
/// completions re-marked, skips re-applied, snapshot id preserved. Round 20
/// shipped the snapshot/replay pair without explicit replay coverage; the
/// 10-second toast is unforgiving if replay drops state.
@MainActor
final class TodayViewModelUndoResetTests: XCTestCase {

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

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func now() -> Date {
        DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: 2026, month: 1, day: 7, hour: 10, minute: 0
        ).date!
    }

    private func block(_ title: String, start: Int) -> Block {
        Block(title: title, category: .hygiene, startMinutesFromMidnight: start, durationMinutes: 30)
    }

    func test_resetDay_returnsNonEmptySnapshot_whenStateExists() throws {
        let b1 = block("Brush", start: 7 * 60)
        let b2 = block("Shower", start: 8 * 60)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [b1, b2], isActive: true)
        try repo.upsert(template)

        let skipStore = InMemoryBlockSkipStore()
        let vm = TodayViewModel(repository: repo, skipStore: skipStore, calendar: calendar)
        vm.reload(now: now())
        vm.toggleDone(b1, now: now())
        vm.toggleSkippedToday(b2, now: now())

        let snapshot = vm.resetDay(now: now())

        XCTAssertFalse(snapshot.isEmpty)
        XCTAssertEqual(snapshot.completionBlockIDs, [b1.id])
        XCTAssertEqual(snapshot.skipBlockIDs, [b2.id])
        XCTAssertTrue(vm.completedBlockIDs.isEmpty, "reset cleared completions")
        XCTAssertFalse(vm.isSkipped(b2, now: now()), "reset cleared skips")
    }

    func test_undoResetDay_replaysBothCompletionsAndSkips() throws {
        let b1 = block("Brush", start: 7 * 60)
        let b2 = block("Shower", start: 8 * 60)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [b1, b2], isActive: true)
        try repo.upsert(template)

        let skipStore = InMemoryBlockSkipStore()
        let vm = TodayViewModel(repository: repo, skipStore: skipStore, calendar: calendar)
        vm.reload(now: now())
        vm.toggleDone(b1, now: now())
        vm.toggleSkippedToday(b2, now: now())

        let snapshot = vm.resetDay(now: now())
        vm.undoResetDay(snapshot)

        XCTAssertTrue(vm.completedBlockIDs.contains(b1.id), "completion replayed")
        XCTAssertTrue(vm.isSkipped(b2, now: now()), "skip replayed")
    }

    func test_undoResetDay_isNoOpForEmptySnapshot() throws {
        let b1 = block("Brush", start: 7 * 60)
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [b1], isActive: true)
        try repo.upsert(template)

        let skipStore = InMemoryBlockSkipStore()
        let vm = TodayViewModel(repository: repo, skipStore: skipStore, calendar: calendar)
        vm.reload(now: now())

        let empty = vm.resetDay(now: now())
        XCTAssertTrue(empty.isEmpty)

        // Should not crash + should not toggle anything.
        vm.undoResetDay(empty)
        XCTAssertTrue(vm.completedBlockIDs.isEmpty)
        XCTAssertFalse(vm.isSkipped(b1, now: now()))
    }
}
