import Foundation

/// Round-18 slice 6: pure helper that flags pairs of blocks whose time
/// windows overlap inside a single `RoutineTemplate`. The `TemplateEditor`
/// shows a per-block warning chip when its `id` appears in the conflict
/// set so the user can spot the overlap before saving.
public enum BlockConflictDetector {

    /// Set of block IDs that overlap with at least one other block in
    /// `blocks`. Touching boundaries (one block ends exactly when the next
    /// starts) are NOT flagged.
    public static func conflictingIDs(in blocks: [Block]) -> Set<UUID> {
        var result: Set<UUID> = []
        guard blocks.count > 1 else { return result }
        let sorted = blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
        for (index, lhs) in sorted.enumerated() {
            let lhsEnd = lhs.startMinutesFromMidnight + lhs.durationMinutes
            for rhs in sorted.dropFirst(index + 1) {
                if rhs.startMinutesFromMidnight >= lhsEnd { break }
                result.insert(lhs.id)
                result.insert(rhs.id)
            }
        }
        return result
    }
}
