import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class TemplateEditorViewModelTests: XCTestCase {

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

    private func makeTemplate(starts: [Int]) throws -> RoutineTemplate {
        let template = RoutineTemplate(name: "T", dayType: .weekday)
        try repo.upsert(template)
        for (index, start) in starts.enumerated() {
            let block = Block(
                title: "B\(index)",
                category: .hygiene,
                startMinutesFromMidnight: start,
                durationMinutes: 30
            )
            try repo.upsert(block, in: template)
        }
        return template
    }

    func test_move_swapsAdjacentStartTimesPreservingSchedule() throws {
        let template = try makeTemplate(starts: [7 * 60, 9 * 60, 11 * 60])
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        let originalIDs = viewModel.sortedBlocks.map(\.id)

        // Move block at index 0 to position 2 (drop after index 1).
        try viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        let after = viewModel.sortedBlocks
        // Slot start times unchanged.
        XCTAssertEqual(after.map(\.startMinutesFromMidnight), [7 * 60, 9 * 60, 11 * 60])
        // Original block-0 is now in slot index 1 (the toOffset:2 means
        // "place before what was index 2" → after the move, source ends up
        // at new index 1).
        XCTAssertEqual(after[0].id, originalIDs[1])
        XCTAssertEqual(after[1].id, originalIDs[0])
        XCTAssertEqual(after[2].id, originalIDs[2])
    }

    func test_move_isNoOpWhenSourceEqualsDestination() throws {
        let template = try makeTemplate(starts: [7 * 60, 9 * 60])
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        let originalIDs = viewModel.sortedBlocks.map(\.id)

        try viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 0)

        let after = viewModel.sortedBlocks
        XCTAssertEqual(after.map(\.id), originalIDs)
        XCTAssertEqual(after.map(\.startMinutesFromMidnight), [7 * 60, 9 * 60])
    }

    func test_move_emptyTemplateIsNoOp() throws {
        let template = try makeTemplate(starts: [])
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        try viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 0)
        XCTAssertTrue(viewModel.sortedBlocks.isEmpty)
    }

    /// Round 17 wire: insertPreset appends every seed block, shifting their
    /// start minutes so the bundle starts after the existing last block's end.
    func test_insertPreset_appendsSeedsShiftedAfterLastBlock() throws {
        let template = try makeTemplate(starts: [8 * 60])  // last block ends at 8:30
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        let beforeCount = viewModel.sortedBlocks.count

        try viewModel.insertPreset(.workday)  // seeds at 9:00, 10:30, 13:00

        let after = viewModel.sortedBlocks
        let workdaySeeds = TemplatePresetSeeds.Preset.workday.seeds
        XCTAssertEqual(after.count, beforeCount + workdaySeeds.count)
        // First seed was at 9:00 (540 min) and lastEnd was 510 min → no shift
        // since 9:00 > lastEnd. Spacing between inserted seeds is preserved.
        let inserted = Array(after.dropFirst(beforeCount))
        let insertedStarts = inserted.map(\.startMinutesFromMidnight)
        let seedStarts = workdaySeeds.map(\.startMinutesFromMidnight)
        let insertedDeltas = zip(insertedStarts.dropFirst(), insertedStarts).map { $0 - $1 }
        let seedDeltas = zip(seedStarts.dropFirst(), seedStarts).map { $0 - $1 }
        XCTAssertEqual(insertedDeltas, seedDeltas, "preset relative spacing preserved")
    }

    /// Round 17: when the template's last block ends after the preset's first
    /// seed, every seed shifts by `(lastEnd - firstSeed)` so they fit at the end.
    func test_insertPreset_shiftsSeedsWhenTemplateExtendsPastFirstSeed() throws {
        let template = try makeTemplate(starts: [10 * 60])  // last ends at 10:30 = 630
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)

        try viewModel.insertPreset(.morningRoutine)  // seeds start 7:00, 7:10, 7:30

        let inserted = viewModel.sortedBlocks.dropFirst()  // skip the original block
        // First inserted seed should be at 10:30 = 630, not 7:00 = 420.
        XCTAssertEqual(inserted.first?.startMinutesFromMidnight, 10 * 60 + 30)
    }

    /// Round 18 slice 8: undoLastPresetInsertion deletes only the blocks
    /// that the most recent insertPreset added — pre-existing blocks remain.
    func test_undoLastPresetInsertion_removesOnlyJustInsertedBlocks() throws {
        let template = try makeTemplate(starts: [8 * 60])
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        let preexistingIDs = Set(viewModel.sortedBlocks.map(\.id))

        try viewModel.insertPreset(.workday)
        XCTAssertGreaterThan(viewModel.sortedBlocks.count, preexistingIDs.count)

        try viewModel.undoLastPresetInsertion()
        let remaining = Set(viewModel.sortedBlocks.map(\.id))
        XCTAssertEqual(remaining, preexistingIDs)
        XCTAssertTrue(viewModel.lastInsertedPresetBlockIDs.isEmpty)
    }

    func test_undoLastPresetInsertion_isNoOpWhenNothingTracked() throws {
        let template = try makeTemplate(starts: [8 * 60])
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        let countBefore = viewModel.sortedBlocks.count
        try viewModel.undoLastPresetInsertion()
        XCTAssertEqual(viewModel.sortedBlocks.count, countBefore)
    }

    func test_move_preservesEachBlockDurationWhenSwapped() throws {
        let template = RoutineTemplate(name: "Durations", dayType: .weekday)
        try repo.upsert(template)
        try repo.upsert(
            Block(title: "Short", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 15),
            in: template
        )
        try repo.upsert(
            Block(title: "Long", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 90),
            in: template
        )
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)

        try viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        let after = viewModel.sortedBlocks
        XCTAssertEqual(after.first?.title, "Long")
        XCTAssertEqual(after.first?.durationMinutes, 90)
        XCTAssertEqual(after.last?.title, "Short")
        XCTAssertEqual(after.last?.durationMinutes, 15)
    }
}
