import Foundation
import SwiftData

/// One completion record for a `Block` on a specific calendar day.
///
/// Stored as a separate `@Model` (rather than a flag on `Block`) so the
/// "done" state is per-day instead of single-shot, which matches how a
/// recurring routine is actually used.
@Model
public final class BlockCompletion {
    public var id: UUID
    /// `Block.id` of the completed block. Stored as a UUID copy so the
    /// completion record survives even if the block is later deleted.
    public var blockID: UUID
    /// Calendar day on which the block was marked done — always
    /// `Calendar.startOfDay(for:)` of the moment of completion.
    public var dayStart: Date
    public var completedAt: Date

    public init(
        id: UUID = UUID(),
        blockID: UUID,
        dayStart: Date,
        completedAt: Date
    ) {
        self.id = id
        self.blockID = blockID
        self.dayStart = dayStart
        self.completedAt = completedAt
    }
}
