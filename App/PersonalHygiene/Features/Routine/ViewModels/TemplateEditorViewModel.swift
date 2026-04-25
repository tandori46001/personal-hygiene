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
}
