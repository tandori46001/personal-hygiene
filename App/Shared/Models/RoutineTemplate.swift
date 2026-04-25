import Foundation

/// A reusable routine template tied to a day type. Generates the daily schedule.
public struct RoutineTemplate: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var dayType: DayType
    public var blocks: [Block]
    public var version: Int

    public init(
        id: UUID = UUID(),
        name: String,
        dayType: DayType,
        blocks: [Block] = [],
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.dayType = dayType
        self.blocks = blocks
        self.version = version
    }

    public var sortedBlocks: [Block] {
        blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }
}
