import Foundation
import Observation

@Observable
@MainActor
final class HousekeepingListViewModel {

    private let service: any HousekeepingService
    private let calendar: Calendar

    var tasks: [HousekeepingTask] = []
    /// Active room filter. `nil` means show every task. Non-nil with empty
    /// string is reserved for "Unsorted" (tasks with no room set).
    var roomFilter: RoomFilter = .all
    var errorMessage: String?

    enum RoomFilter: Equatable, Hashable {
        case all
        case unsorted
        case named(String)
    }

    init(service: any HousekeepingService, calendar: Calendar = .autoupdatingCurrent) {
        self.service = service
        self.calendar = calendar
    }

    /// Distinct room labels that currently appear on at least one task,
    /// alphabetised. Used to populate the filter picker.
    var availableRooms: [String] {
        Array(Set(tasks.compactMap(\.room))).sorted()
    }

    var hasUnsortedTasks: Bool {
        tasks.contains { $0.room == nil }
    }

    var filteredTasks: [HousekeepingTask] {
        switch roomFilter {
        case .all: return tasks
        case .unsorted: return tasks.filter { $0.room == nil }
        case .named(let room): return tasks.filter { $0.room == room }
        }
    }

    func reload() {
        do {
            tasks = try service.allTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(title: String, recurrence: HousekeepingRecurrence, escalationDays: Int, room: String? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let task = HousekeepingTask(
                title: trimmed,
                recurrence: recurrence,
                escalationDays: escalationDays,
                room: room
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
