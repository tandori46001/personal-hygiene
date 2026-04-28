import Foundation
import SwiftData

/// Round-25 slice T4.29: exports only the *archived* templates as a
/// standalone snapshot. Useful when the user wants to share their old
/// templates with a friend without leaking the rest of their data.
@MainActor
public enum BackupArchiveExporter {

    public static func export(
        from context: ModelContext,
        archivedIDs: Set<UUID> = TemplateArchiveStore.archivedIDs()
    ) throws -> BackupSnapshot {
        let allTemplates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        let archivedTemplates = allTemplates.filter { archivedIDs.contains($0.id) }
        return BackupSnapshot(
            templates: archivedTemplates.map(templatePayload(from:)),
            completions: [],
            hydration: [],
            housekeeping: [],
            trips: [],
            diagnostics: nil,
            mood: nil,
            moodWeeklyGoal: nil,
            archivedTemplateIDs: Array(archivedIDs)
        )
    }

    private static func templatePayload(
        from template: RoutineTemplate
    ) -> BackupSnapshot.TemplatePayload {
        BackupSnapshot.TemplatePayload(
            id: template.id,
            name: template.name,
            dayType: template.dayType.rawValue,
            isActive: template.isActive,
            blocks: template.sortedBlocks.map(blockPayload(from:))
        )
    }

    private static func blockPayload(
        from block: Block
    ) -> BackupSnapshot.BlockPayload {
        BackupSnapshot.BlockPayload(
            id: block.id,
            title: block.title,
            category: block.category.rawValue,
            startMinutesFromMidnight: block.startMinutesFromMidnight,
            durationMinutes: block.durationMinutes,
            notificationLeadMinutes: block.notificationLeadMinutes,
            isDeepFocus: block.isDeepFocus,
            notes: block.notes
        )
    }
}
