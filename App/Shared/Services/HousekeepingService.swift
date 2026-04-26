import Foundation
import SwiftData

/// Status of a housekeeping task on a given date — drives the UI badge.
public enum HousekeepingStatus: String, Equatable, Sendable {
    /// Never completed and never due before today.
    case pending
    /// Due today or earlier within the recurrence period.
    case dueToday
    /// Past `nextDueDate + escalationDays`.
    case overdue
    /// Up to date — last completed inside the current recurrence period.
    case ok
}

public enum HousekeepingScheduler {

    /// Day on which the task is next due. `nil` when never completed and
    /// recurrence hasn't fired yet from creation.
    public static func nextDueDate(
        for task: HousekeepingTask,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        guard let last = task.lastCompletedAt else { return nil }
        return calendar.date(byAdding: .day, value: task.recurrence.days, to: last)
    }

    public static func status(
        for task: HousekeepingTask,
        on now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> HousekeepingStatus {
        let today = calendar.startOfDay(for: now)
        guard let nextDue = nextDueDate(for: task, calendar: calendar) else {
            return .pending
        }
        let nextDueDay = calendar.startOfDay(for: nextDue)
        let escalated = calendar.date(byAdding: .day, value: task.escalationDays, to: nextDueDay)
        if let escalated, today > escalated {
            return .overdue
        }
        if today >= nextDueDay {
            return .dueToday
        }
        return .ok
    }
}

@MainActor
public protocol HousekeepingService {
    func allTasks() throws -> [HousekeepingTask]
    func upsert(_ task: HousekeepingTask) throws
    func delete(_ task: HousekeepingTask) throws
    func markDone(_ task: HousekeepingTask, at completedAt: Date) throws
}

@MainActor
public final class SwiftDataHousekeepingService: HousekeepingService {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func allTasks() throws -> [HousekeepingTask] {
        let descriptor = FetchDescriptor<HousekeepingTask>(sortBy: [SortDescriptor(\.title)])
        return try context.fetch(descriptor)
    }

    public func upsert(_ task: HousekeepingTask) throws {
        if task.modelContext == nil {
            context.insert(task)
        }
        try context.save()
    }

    public func delete(_ task: HousekeepingTask) throws {
        context.delete(task)
        try context.save()
    }

    public func markDone(_ task: HousekeepingTask, at completedAt: Date = Date()) throws {
        task.lastCompletedAt = completedAt
        try context.save()
    }
}
