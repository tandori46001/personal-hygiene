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
        try context.save()
    }

    public func delete(_ template: RoutineTemplate) throws {
        context.delete(template)
        try context.save()
    }

    public func setActive(_ template: RoutineTemplate, for dayType: DayType) throws {
        let templateID = template.id
        for existing in try allTemplates() where existing.dayType == dayType {
            existing.isActive = (existing.id == templateID)
        }
        try context.save()
    }

    public func upsert(_ block: Block, in template: RoutineTemplate) throws {
        if block.modelContext == nil {
            template.blocks.append(block)
        }
        try context.save()
    }

    public func delete(_ block: Block) throws {
        context.delete(block)
        try context.save()
    }
}
