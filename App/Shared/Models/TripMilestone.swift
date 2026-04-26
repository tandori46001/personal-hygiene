import Foundation
import SwiftData

/// A pre-trip checkpoint — e.g. "Buy currency" or "Confirm hotel" — fired
/// `daysBefore` the trip's start date.
@Model
public final class TripMilestone {
    public var id: UUID
    public var title: String
    public var daysBefore: Int
    public var isComplete: Bool

    public var trip: Trip?

    public init(
        id: UUID = UUID(),
        title: String,
        daysBefore: Int,
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.daysBefore = max(0, daysBefore)
        self.isComplete = isComplete
    }
}
