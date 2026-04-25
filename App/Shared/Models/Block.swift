import Foundation
import SwiftData

/// A single time-blocked item in the user's daily routine.
@Model
public final class Block {
    public var id: UUID
    public var title: String
    public var category: BlockCategory
    public var startMinutesFromMidnight: Int
    public var durationMinutes: Int
    public var notes: String?
    public var notificationLeadMinutes: Int
    public var isDeepFocus: Bool

    public var template: RoutineTemplate?

    public init(
        id: UUID = UUID(),
        title: String,
        category: BlockCategory,
        startMinutesFromMidnight: Int,
        durationMinutes: Int,
        notes: String? = nil,
        notificationLeadMinutes: Int = 15,
        isDeepFocus: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.notificationLeadMinutes = notificationLeadMinutes
        self.isDeepFocus = isDeepFocus
    }

    public var endMinutesFromMidnight: Int {
        startMinutesFromMidnight + durationMinutes
    }
}
