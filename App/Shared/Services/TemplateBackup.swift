import Foundation

/// Round-12 slice 30: import/export of a single `RoutineTemplate` as a JSON
/// document. Keeps the data shape decoupled from `BackupService` (which
/// rounds the entire app) so users can share templates by copy/paste.
public enum TemplateBackup {

    public struct Payload: Codable, Equatable, Sendable {
        public let version: Int
        public let template: TemplateDTO

        public init(version: Int = 1, template: TemplateDTO) {
            self.version = version
            self.template = template
        }
    }

    public struct TemplateDTO: Codable, Equatable, Sendable {
        public let name: String
        public let dayType: String
        public let blocks: [BlockDTO]

        public init(name: String, dayType: String, blocks: [BlockDTO]) {
            self.name = name
            self.dayType = dayType
            self.blocks = blocks
        }
    }

    public struct BlockDTO: Codable, Equatable, Sendable {
        public let title: String
        public let category: String
        public let startMinutesFromMidnight: Int
        public let durationMinutes: Int
        public let notes: String?
        public let notificationLeadMinutes: Int
        public let isDeepFocus: Bool
        public let medicationConceptIdentifier: String?
    }

    public static func encode(_ template: RoutineTemplate) throws -> Data {
        let dto = TemplateDTO(
            name: template.name,
            dayType: template.dayType.rawValue,
            blocks: template.sortedBlocks.map { block in
                BlockDTO(
                    title: block.title,
                    category: block.category.rawValue,
                    startMinutesFromMidnight: block.startMinutesFromMidnight,
                    durationMinutes: block.durationMinutes,
                    notes: block.notes,
                    notificationLeadMinutes: block.notificationLeadMinutes,
                    isDeepFocus: block.isDeepFocus,
                    medicationConceptIdentifier: block.medicationConceptIdentifier
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Payload(template: dto))
    }

    public static func decode(_ data: Data) throws -> Payload {
        try JSONDecoder().decode(Payload.self, from: data)
    }

    public static func makeTemplate(from payload: Payload) -> RoutineTemplate {
        let dayType = DayType(rawValue: payload.template.dayType) ?? .weekday
        let blocks = payload.template.blocks.map { dto -> Block in
            let category = BlockCategory(rawValue: dto.category) ?? .work
            return Block(
                title: dto.title,
                category: category,
                startMinutesFromMidnight: dto.startMinutesFromMidnight,
                durationMinutes: dto.durationMinutes,
                notes: dto.notes,
                notificationLeadMinutes: dto.notificationLeadMinutes,
                isDeepFocus: dto.isDeepFocus,
                medicationConceptIdentifier: dto.medicationConceptIdentifier
            )
        }
        return RoutineTemplate(
            name: payload.template.name,
            dayType: dayType,
            blocks: blocks,
            isActive: false
        )
    }
}
