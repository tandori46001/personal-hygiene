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
    /// Round-18 slice 12: rolling 30-day adherence so the user can see a
    /// longer trend than the 7-day overall row provides. `nil` until the
    /// first reload completes.
    var thirtyDayAdherence: Double?
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

            // Round-18 slice 12: 30-day adherence rolls up the same overall
            // formula across a longer window, fetched once per reload.
            let monthStart = calendar.date(byAdding: .day, value: -29, to: end) ?? start
            var monthLogs: [MedicationDoseLog] = []
            for conceptID in medicationConceptIDs {
                let logs = try await service.doseLogs(for: conceptID, from: monthStart, to: now)
                monthLogs.append(contentsOf: logs)
            }
            thirtyDayAdherence = MedicationCompliance.overallAdherence(
                from: monthLogs,
                between: monthStart,
                and: now
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Round-17 wire: snapshot of medication-only completions in the trailing
    /// `days` window for `DoseHistoryView`. Read-once; the view doesn't poll.
    func doseHistory(days: Int = 30, now: Date = Date()) -> [MedicationDoseHistory.Entry] {
        do {
            let templates = try repository.allTemplates()
            let blocks = templates.flatMap(\.blocks)
            let completions = try repository.recentCompletions(
                days: days,
                now: now,
                calendar: calendar
            )
            return MedicationDoseHistory.recent(
                completions: completions,
                blocks: blocks,
                days: days,
                now: now,
                calendar: calendar
            )
        } catch {
            errorMessage = error.localizedDescription
            return []
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
