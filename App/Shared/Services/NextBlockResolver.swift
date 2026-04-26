import Foundation

/// Pure function that picks "what's next" from the user's active template:
/// returns the currently-running block if one is in progress, otherwise the
/// next upcoming block today, otherwise `nil`.
///
/// Lives in `Shared/Services/` so widgets, App Intents, and view-models all
/// share the same definition of "next".
public enum NextBlockResolver {

    /// Bundle returned by `resolve(in:at:calendar:)`. Not `Sendable` because
    /// `Block` is a SwiftData `@Model` and crossing actors with a managed
    /// instance is unsafe — callers extract the snapshot fields they need on
    /// the same actor.
    public struct Result {
        public let block: Block
        public let isCurrent: Bool
        public let startMinutesFromMidnight: Int

        public init(block: Block, isCurrent: Bool, startMinutesFromMidnight: Int) {
            self.block = block
            self.isCurrent = isCurrent
            self.startMinutesFromMidnight = startMinutesFromMidnight
        }
    }

    public static func resolve(
        in template: RoutineTemplate?,
        at now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Result? {
        guard let template else { return nil }
        let blocks = template.sortedBlocks
        let nowMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        if let current = blocks.first(where: {
            $0.startMinutesFromMidnight <= nowMinutes && $0.endMinutesFromMidnight > nowMinutes
        }) {
            return Result(
                block: current,
                isCurrent: true,
                startMinutesFromMidnight: current.startMinutesFromMidnight
            )
        }
        if let upcoming = blocks.first(where: { $0.startMinutesFromMidnight > nowMinutes }) {
            return Result(
                block: upcoming,
                isCurrent: false,
                startMinutesFromMidnight: upcoming.startMinutesFromMidnight
            )
        }
        return nil
    }
}
