import Foundation

/// Round-23 slice T4.22: lightweight check that runs at bedtime to see
/// whether tomorrow's plan still has all blocks intact + an active
/// template. Surfaces a green/red dot in Today's tomorrow disclosure.
public enum BedtimePlanCheck {

    public enum Verdict: Equatable, Sendable {
        case ready
        case noTemplate
        case empty
        case conflict
    }

    public static func evaluate(blocks: [Block]) -> Verdict {
        guard !blocks.isEmpty else { return .empty }
        if !BlockConflictDetector.conflictingIDs(in: blocks).isEmpty {
            return .conflict
        }
        return .ready
    }
}
