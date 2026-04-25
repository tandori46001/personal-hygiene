import Foundation
import Observation

@Observable
@MainActor
final class MedicationComplianceViewModel {

    private let service: any MedicationService
    private let repository: any RoutineRepository
    private let calendar: Calendar

    var summaries: [DailyCompliance] = []
    var overall: Double = 1.0
    var isAvailable: Bool = false
    var errorMessage: String?

    init(
        service: any MedicationService,
        repository: any RoutineRepository,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.service = service
        self.repository = repository
        self.calendar = calendar
    }

    func reload(now: Date = Date()) async {
        isAvailable = service.isAvailable
        guard isAvailable else { return }

        do {
            let medicationConceptIDs = try collectLinkedConceptIDs()
            guard !medicationConceptIDs.isEmpty else {
                summaries = []
                overall = 1.0
                return
            }

            let end = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end

            var allLogs: [MedicationDoseLog] = []
            for conceptID in medicationConceptIDs {
                let logs = try await service.doseLogs(for: conceptID, from: start, to: now)
                allLogs.append(contentsOf: logs)
            }

            summaries = MedicationCompliance.dailySummaries(
                from: allLogs,
                between: start,
                and: now,
                calendar: calendar
            )
            overall = MedicationCompliance.overallAdherence(from: allLogs, between: start, and: now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func collectLinkedConceptIDs() throws -> Set<String> {
        let templates = try repository.allTemplates()
        var ids: Set<String> = []
        for template in templates {
            for block in template.blocks {
                if let id = block.medicationConceptIdentifier {
                    ids.insert(id)
                }
            }
        }
        return ids
    }
}
