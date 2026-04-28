import Foundation

/// Round-25 slice T7.48: enhanced version of `BlockTitleSuggestions` that
/// ranks history matches by recency *and* prefix-match strength so the
/// editor surfaces "Take morning meds" before "Reading" when the user has
/// typed "T". Pure helper.
public enum BlockTitleHistoryAutocompleteV2 {

    public struct Suggestion: Equatable, Sendable {
        public let title: String
        public let lastUsed: Date
    }

    public static func suggest(
        history: [Suggestion],
        query: String,
        limit: Int = 5
    ) -> [String] {
        let normalized = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !normalized.isEmpty else {
            return Array(
                history
                    .sorted { $0.lastUsed > $1.lastUsed }
                    .prefix(limit)
                    .map(\.title)
            )
        }
        let scored = history.compactMap { entry -> (Suggestion, Int)? in
            let lower = entry.title.lowercased()
            if lower.hasPrefix(normalized) { return (entry, 3) }
            if lower.contains(" \(normalized)") { return (entry, 2) }
            if lower.contains(normalized) { return (entry, 1) }
            return nil
        }
        return scored
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.lastUsed > rhs.0.lastUsed
            }
            .prefix(limit)
            .map(\.0.title)
    }
}
