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
}
