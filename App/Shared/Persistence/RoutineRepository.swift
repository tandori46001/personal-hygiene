import Foundation
import SwiftData

/// Read-write access to routine templates and their blocks.
///
/// Concrete implementations: `SwiftDataRoutineRepository` (production),
/// in-memory containers for previews / unit tests.
@MainActor
public protocol RoutineRepository {
    func allTemplates() throws -> [RoutineTemplate]
    func activeTemplate(for dayType: DayType) throws -> RoutineTemplate?
    func upsert(_ template: RoutineTemplate) throws
    func delete(_ template: RoutineTemplate) throws
    func setActive(_ template: RoutineTemplate, for dayType: DayType) throws
    func upsert(_ block: Block, in template: RoutineTemplate) throws
    func delete(_ block: Block) throws

    /// Mark `block` as done on the calendar day of `now`. Idempotent — if
    /// a completion already exists for that block + day, this is a no-op.
    func markDone(_ block: Block, on now: Date, calendar: Calendar) throws
    /// Remove the completion for `block` on the calendar day of `now`, if any.
    func unmarkDone(_ block: Block, on now: Date, calendar: Calendar) throws
    /// Return `true` when a completion exists for `block` on the calendar day of `now`.
    func isDone(_ block: Block, on now: Date, calendar: Calendar) throws -> Bool
    /// All completion records on the calendar day of `now`, in insertion order.
    func completions(on now: Date, calendar: Calendar) throws -> [BlockCompletion]
    /// Round-17: completions in the trailing `days` window ending at `now`,
    /// newest first by `completedAt`. Used by `MedicationDoseHistory` to
    /// render the 30-day dose history feed.
    func recentCompletions(days: Int, now: Date, calendar: Calendar) throws -> [BlockCompletion]
}

@MainActor
public final class SwiftDataRoutineRepository: RoutineRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func allTemplates() throws -> [RoutineTemplate] {
        let descriptor = FetchDescriptor<RoutineTemplate>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    public func activeTemplate(for dayType: DayType) throws -> RoutineTemplate? {
        try allTemplates().first { $0.dayType == dayType && $0.isActive }
    }

    public func upsert(_ template: RoutineTemplate) throws {
        if template.modelContext == nil {
            context.insert(template)
        }
        try saveAndNotify()
    }

    public func delete(_ template: RoutineTemplate) throws {
        context.delete(template)
        try saveAndNotify()
    }

    public func setActive(_ template: RoutineTemplate, for dayType: DayType) throws {
        let templateID = template.id
        for existing in try allTemplates() where existing.dayType == dayType {
            existing.isActive = (existing.id == templateID)
        }
        try saveAndNotify()
    }

    public func upsert(_ block: Block, in template: RoutineTemplate) throws {
        if block.modelContext == nil {
            template.blocks.append(block)
        }
        try saveAndNotify()
    }

    public func delete(_ block: Block) throws {
        context.delete(block)
        try saveAndNotify()
    }

    public func markDone(_ block: Block, on now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) throws {
        let day = calendar.startOfDay(for: now)
        let blockID = block.id
        if let existing = try fetchCompletion(blockID: blockID, dayStart: day) {
            _ = existing
            return
        }
        let completion = BlockCompletion(blockID: blockID, dayStart: day, completedAt: now)
        context.insert(completion)
        try saveAndNotify()
    }

    public func unmarkDone(_ block: Block, on now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) throws {
        let day = calendar.startOfDay(for: now)
        guard let existing = try fetchCompletion(blockID: block.id, dayStart: day) else { return }
        context.delete(existing)
        try saveAndNotify()
    }

    /// Round-25 fix: every successful repository write posts
    /// `.routineDataChanged` so cross-tab observers (TodayView,
    /// MedicationComplianceView, etc.) refresh without relying on iOS 18
    /// TabView `.onAppear` re-firing — which is unreliable when tabs stay
    /// alive in the hierarchy.
    private func saveAndNotify() throws {
        try context.save()
        NotificationCenter.default.post(name: .routineDataChanged, object: nil)
    }

    public func isDone(
        _ block: Block,
        on now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) throws -> Bool {
        let day = calendar.startOfDay(for: now)
        return try fetchCompletion(blockID: block.id, dayStart: day) != nil
    }

    public func completions(
        on now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) throws -> [BlockCompletion] {
        let day = calendar.startOfDay(for: now)
        let descriptor = FetchDescriptor<BlockCompletion>(
            predicate: #Predicate { $0.dayStart == day },
            sortBy: [SortDescriptor(\.completedAt)]
        )
        return try context.fetch(descriptor)
    }

    public func recentCompletions(
        days: Int,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) throws -> [BlockCompletion] {
        let cutoff = calendar.date(byAdding: .day, value: -max(0, days), to: now)
            ?? now.addingTimeInterval(-Double(days * 86_400))
        let descriptor = FetchDescriptor<BlockCompletion>(
            predicate: #Predicate { $0.completedAt >= cutoff },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    private func fetchCompletion(blockID: UUID, dayStart: Date) throws -> BlockCompletion? {
        let descriptor = FetchDescriptor<BlockCompletion>(
            predicate: #Predicate { $0.blockID == blockID && $0.dayStart == dayStart }
        )
        return try context.fetch(descriptor).first
    }
}
