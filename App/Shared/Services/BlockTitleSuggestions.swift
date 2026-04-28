import Foundation

/// Round-20 slice T4.20: suggests recently-used block titles for a given
/// `BlockCategory`. Pulls from every template the repository knows about,
/// returning up to `limit` distinct titles preserving most-recent-first.
///
/// "Recent" here means *latest in the sorted order across templates* —
/// `RoutineTemplate` doesn't carry a created-at timestamp, so we approximate
/// by walking templates in reverse and de-duplicating titles within the
/// same category.
public enum BlockTitleSuggestions {

    public static func recent(
        in templates: [RoutineTemplate],
        category: BlockCategory,
        limit: Int = 5
    ) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for template in templates.reversed() {
            for block in template.sortedBlocks.reversed() where block.category == category {
                let trimmed = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || seen.contains(trimmed) { continue }
                seen.insert(trimmed)
                result.append(trimmed)
                if result.count >= limit { return result }
            }
        }
        return result
    }
}
