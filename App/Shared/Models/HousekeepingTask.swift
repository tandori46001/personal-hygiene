import Foundation
import SwiftData

public enum HousekeepingRecurrence: String, CaseIterable, Codable, Sendable {
    case daily
    case weekly
    case biweekly
    case monthly

    /// Recurrence period expressed in days.
    public var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}

@Model
public final class HousekeepingTask {
    public var id: UUID
    public var title: String
    public var recurrence: HousekeepingRecurrence
    /// Last time the task was completed. `nil` means never completed.
    public var lastCompletedAt: Date?
    /// Days past `nextDueDate` before the task is treated as `overdue`.
    public var escalationDays: Int

    public init(
        id: UUID = UUID(),
        title: String,
        recurrence: HousekeepingRecurrence,
        lastCompletedAt: Date? = nil,
        escalationDays: Int = 2
    ) {
        self.id = id
        self.title = title
        self.recurrence = recurrence
        self.lastCompletedAt = lastCompletedAt
        self.escalationDays = max(0, escalationDays)
    }
}
