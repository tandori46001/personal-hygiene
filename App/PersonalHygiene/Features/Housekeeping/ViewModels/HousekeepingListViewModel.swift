import Foundation
import Observation

@Observable
@MainActor
final class HousekeepingListViewModel {

    private let service: any HousekeepingService
    private let calendar: Calendar

    var tasks: [HousekeepingTask] = []
    var errorMessage: String?

    init(service: any HousekeepingService, calendar: Calendar = .autoupdatingCurrent) {
        self.service = service
        self.calendar = calendar
    }

    func reload() {
        do {
            tasks = try service.allTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(title: String, recurrence: HousekeepingRecurrence, escalationDays: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let task = HousekeepingTask(
                title: trimmed,
                recurrence: recurrence,
                escalationDays: escalationDays
            )
            try service.upsert(task)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markDone(_ task: HousekeepingTask, now: Date = Date()) {
        do {
            try service.markDone(task, at: now)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ task: HousekeepingTask) {
        do {
            try service.delete(task)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func status(for task: HousekeepingTask, now: Date = Date()) -> HousekeepingStatus {
        HousekeepingScheduler.status(for: task, on: now, calendar: calendar)
    }
}
