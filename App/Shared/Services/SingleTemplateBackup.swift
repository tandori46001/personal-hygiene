import Foundation

/// Round-23 slice T4.23: tiny variant of `TemplateBackup` that round-trips
/// a single `RoutineTemplate` payload through JSON. Round 12 shipped a
/// multi-template backup; this is the single-template companion shaped
/// for share-sheet usage.
public enum SingleTemplateBackup {

    public struct Payload: Codable, Equatable, Sendable {
        public let version: Int
        public let exportedAt: Date
        public let template: BackupSnapshot.TemplatePayload
    }

    public static func encode(_ template: RoutineTemplate) throws -> Data {
        let payload = Payload(
            version: 1,
            exportedAt: Date(),
            template: BackupSnapshot.TemplatePayload(
                id: template.id,
                name: template.name,
                dayType: template.dayType.rawValue,
                isActive: false,
                blocks: template.sortedBlocks.map { block in
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
            )
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(payload)
    }

    public static func decode(_ data: Data) throws -> Payload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(Payload.self, from: data)
    }
}
