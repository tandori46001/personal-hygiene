import Foundation
import SwiftData

/// One sip — `milliliters` consumed at `drankAt`. Persisted alongside routine
/// data so the M5 dashboard and CloudKit sync (slice 2) treat all of the
/// user's daily wellness data as a single graph.
@Model
public final class HydrationLog {
    public var id: UUID
    public var milliliters: Int
    public var drankAt: Date

    public init(id: UUID = UUID(), milliliters: Int, drankAt: Date) {
        self.id = id
        self.milliliters = milliliters
        self.drankAt = drankAt
    }
}
