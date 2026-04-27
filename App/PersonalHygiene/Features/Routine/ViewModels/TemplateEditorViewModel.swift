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

    /// Drag-to-reorder semantics for a time-anchored schedule: the sequence
    /// of start times stays fixed (07:00, 09:00, 11:00 …), but blocks swap
    /// the slot they occupy according to the user's gesture. Each block
    /// keeps its own `durationMinutes`; only `startMinutesFromMidnight` is
    /// reassigned, so a 30-min block dragged into the 09:00 slot becomes a
    /// 30-min block at 09:00.
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
