import Foundation
import SwiftData

/// A reusable routine template tied to a day type. Generates the daily schedule.
@Model
public final class RoutineTemplate {
    public var id: UUID
    public var name: String
    public var dayType: DayType
    public var version: Int
    public var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \Block.template)
    public var blocks: [Block]

    public init(
        id: UUID = UUID(),
        name: String,
        dayType: DayType,
        blocks: [Block] = [],
        version: Int = 1,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dayType = dayType
        self.version = version
        self.isActive = isActive
        self.blocks = blocks
    }

    public var sortedBlocks: [Block] {
        blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }
}
