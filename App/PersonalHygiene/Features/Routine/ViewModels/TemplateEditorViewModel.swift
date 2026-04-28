import Foundation
import Observation

@Observable
@MainActor
final class TemplateEditorViewModel {

    let template: RoutineTemplate
    private let repository: any RoutineRepository

    var name: String
    var dayType: DayType

    init(template: RoutineTemplate, repository: any RoutineRepository) {
        self.template = template
        self.repository = repository
        self.name = template.name
        self.dayType = template.dayType
    }

    var sortedBlocks: [Block] {
        template.sortedBlocks
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveMetadata() throws {
        template.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        template.dayType = dayType
        template.version += 1
        try repository.upsert(template)
    }

    func add(_ block: Block) throws {
        try repository.upsert(block, in: template)
    }

    func update(_ block: Block, with editor: BlockEditorViewModel) throws {
        editor.apply(to: block)
        try repository.upsert(block, in: template)
    }

    func delete(_ block: Block) throws {
        try repository.delete(block)
    }

    /// Round-19 slice T5.21: clone `block` into the same template, placing
    /// the copy immediately after the source block. Start time is bumped by
    /// the source's own duration (so a 30-min block at 09:00 spawns a clone
    /// at 09:30) and clamped to the last minute of the day. The clone keeps
    /// the same category, notes, lead minutes, and deep-focus flag — the
    /// user usually wants to tweak only one field afterwards.
    func duplicate(_ block: Block) throws {
        let nextStart = min(
            24 * 60 - 1,
            block.startMinutesFromMidnight + max(1, block.durationMinutes)
        )
        let clone = Block(
            title: block.title,
            category: block.category,
            startMinutesFromMidnight: nextStart,
            durationMinutes: block.durationMinutes,
            notes: block.notes,
            notificationLeadMinutes: block.notificationLeadMinutes,
            isDeepFocus: block.isDeepFocus
        )
        try repository.upsert(clone, in: template)
    }

    /// Drag-to-reorder semantics for a time-anchored schedule: the sequence
    /// of start times stays fixed (07:00, 09:00, 11:00 …), but blocks swap
    /// the slot they occupy according to the user's gesture. Each block
    /// keeps its own `durationMinutes`; only `startMinutesFromMidnight` is
    /// reassigned, so a 30-min block dragged into the 09:00 slot becomes a
    /// 30-min block at 09:00.
    /// Round-18 slice 8: tracks blocks created by the most recent successful
    /// `insertPreset(_:)` so the editor can offer a 4-second "Undo" affordance.
    /// Cleared by `undoLastPresetInsertion()` or by any subsequent insertion.
    private(set) var lastInsertedPresetBlockIDs: [UUID] = []

    /// Round-17 wire: append every `BlockSeed` in `preset` to this template,
    /// shifting their start times so the bundle starts after the last existing
    /// block. The bundle's relative time spacing (offsets between seeds) is
    /// preserved. No-op if `seeds` is empty.
    func insertPreset(_ preset: TemplatePresetSeeds.Preset) throws {
        let seeds = preset.seeds
        guard !seeds.isEmpty else { return }
        let baseOffset: Int = {
            guard let last = sortedBlocks.last else { return 0 }
            let lastEnd = last.startMinutesFromMidnight + last.durationMinutes
            let firstSeed = seeds.map(\.startMinutesFromMidnight).min() ?? 0
            return max(0, lastEnd - firstSeed)
        }()
        var insertedIDs: [UUID] = []
        for seed in seeds {
            let block = Block(
                title: seed.title,
                category: seed.category,
                startMinutesFromMidnight: min(24 * 60 - 1, seed.startMinutesFromMidnight + baseOffset),
                durationMinutes: seed.durationMinutes
            )
            try repository.upsert(block, in: template)
            insertedIDs.append(block.id)
        }
        lastInsertedPresetBlockIDs = insertedIDs
    }

    /// Round-18 slice 8: deletes the blocks created by the last
    /// `insertPreset(_:)` and clears the tracker. No-op if there's nothing to
    /// undo or the blocks were already removed.
    func undoLastPresetInsertion() throws {
        guard !lastInsertedPresetBlockIDs.isEmpty else { return }
        let ids = Set(lastInsertedPresetBlockIDs)
        for block in sortedBlocks where ids.contains(block.id) {
            try repository.delete(block)
        }
        lastInsertedPresetBlockIDs = []
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        var blocks = sortedBlocks
        guard !blocks.isEmpty else { return }
        let originalStarts = blocks.map(\.startMinutesFromMidnight)
        blocks.move(fromOffsets: source, toOffset: destination)
        for (index, block) in blocks.enumerated() {
            block.startMinutesFromMidnight = originalStarts[index]
        }
        try repository.upsert(template)
    }
}
