import Foundation
import Observation

@Observable
@MainActor
final class TemplateListViewModel {

    private let repository: any RoutineRepository

    var templates: [RoutineTemplate] = []
    var errorMessage: String?

    init(repository: any RoutineRepository) {
        self.repository = repository
    }

    func reload() {
        do {
            templates = try repository.allTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTemplate(name: String, dayType: DayType) -> RoutineTemplate? {
        do {
            let template = RoutineTemplate(name: name, dayType: dayType)
            try repository.upsert(template)
            reload()
            return template
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func delete(_ template: RoutineTemplate) {
        do {
            try repository.delete(template)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setActive(_ template: RoutineTemplate, for dayType: DayType) {
        do {
            try repository.setActive(template, for: dayType)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates a new template with the same `dayType` and a deep copy of every
    /// block (new `Block.id` for each). The copy is never auto-activated.
    /// Returns the new template, or `nil` on failure.
    @discardableResult
    func duplicate(_ source: RoutineTemplate) -> RoutineTemplate? {
        let copy = RoutineTemplate(
            name: source.name + " " + String(localized: "templateList.action.duplicate.suffix"),
            dayType: source.dayType,
            blocks: source.sortedBlocks.map { original in
                Block(
                    title: original.title,
                    category: original.category,
                    startMinutesFromMidnight: original.startMinutesFromMidnight,
                    durationMinutes: original.durationMinutes,
                    notes: original.notes,
                    notificationLeadMinutes: original.notificationLeadMinutes,
                    isDeepFocus: original.isDeepFocus,
                    medicationConceptIdentifier: original.medicationConceptIdentifier,
                    location: original.location
                )
            },
            isActive: false
        )
        do {
            try repository.upsert(copy)
            reload()
            return copy
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Round-22 slice T5.28: variant of `duplicate(_:)` that takes an
    /// explicit replacement name so the swipe-action can pre-fill the
    /// rename sheet without forcing the user through TemplateEditor.
    @discardableResult
    func duplicate(_ source: RoutineTemplate, renamedTo newName: String) -> RoutineTemplate? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let copy = duplicate(source) else { return nil }
        copy.name = trimmed
        do {
            try repository.upsert(copy)
            reload()
            return copy
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
