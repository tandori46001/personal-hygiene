import Foundation

/// Round-21 slice T4.19: extends the binary `BlockConflictDetector` with
/// per-pair overlap data. Where the round-18 detector returns "this block id
/// has at least one conflict", the visualizer needs to render the overlap
/// span ("Standup overlaps with Code review by 30 min") so the user can fix
/// the schedule without trial-and-error.
public enum BlockConflictOverlap {

    public struct Overlap: Equatable, Sendable {
        public let firstID: UUID
        public let secondID: UUID
        public let overlapMinutes: Int
    }

    public static func overlaps(in blocks: [Block]) -> [Overlap] {
        guard blocks.count > 1 else { return [] }
        let sorted = blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
        var result: [Overlap] = []
        for (index, lhs) in sorted.enumerated() {
            let lhsEnd = lhs.startMinutesFromMidnight + lhs.durationMinutes
            for rhs in sorted.dropFirst(index + 1) {
                if rhs.startMinutesFromMidnight >= lhsEnd { break }
                let rhsEnd = rhs.startMinutesFromMidnight + rhs.durationMinutes
                let overlapEnd = min(lhsEnd, rhsEnd)
                let overlap = max(0, overlapEnd - rhs.startMinutesFromMidnight)
                if overlap > 0 {
                    result.append(Overlap(firstID: lhs.id, secondID: rhs.id, overlapMinutes: overlap))
                }
            }
        }
        return result
    }

    /// Returns a human-readable summary like "Standup ↔ Code review · 30 min"
    /// for an overlap pair, looking up titles via `titleByID`.
    public static func summary(
        for overlap: Overlap,
        titleByID: [UUID: String],
        unknownTitle: String = "(?)"
    ) -> String {
        let lhs = titleByID[overlap.firstID] ?? unknownTitle
        let rhs = titleByID[overlap.secondID] ?? unknownTitle
        return "\(lhs) ↔ \(rhs) · \(overlap.overlapMinutes) min"
    }
}
