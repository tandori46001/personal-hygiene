import Foundation

/// Round-21 slice T4.22: parses a one-row-per-block CSV into `Block` value
/// types so the user can paste a spreadsheet of routine items and have them
/// inserted into a template in one go. Pure helper — caller decides what to
/// do with the parsed blocks (insert into template, validate against
/// existing schedule, etc).
///
/// Header is fixed: `title,category,startMinutes,durationMinutes`.
/// `category` accepts a `BlockCategory.rawValue`; unknown categories fall
/// back to `.hygiene` and surface a `categoryFallbackOnRow` warning.
public enum BlockCSVImporter {

    public struct ParseResult: Equatable {
        public let blocks: [Block]
        public let warnings: [String]
    }

    public static let header = "title,category,startMinutes,durationMinutes"

    public static func parse(_ csv: String) -> ParseResult {
        var blocks: [Block] = []
        var warnings: [String] = []
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        guard !lines.isEmpty else {
            return ParseResult(blocks: [], warnings: ["empty input"])
        }
        let dataLines = stripHeader(lines, warnings: &warnings)
        for (offset, line) in dataLines.enumerated() {
            if let block = parseRow(line, row: offset + 1, warnings: &warnings) {
                blocks.append(block)
            }
        }
        return ParseResult(blocks: blocks, warnings: warnings)
    }

    private static func stripHeader(
        _ lines: [Substring],
        warnings: inout [String]
    ) -> ArraySlice<Substring> {
        let normalized = lines[0].trimmingCharacters(in: .whitespaces).lowercased()
        if normalized == header.lowercased() {
            return lines.dropFirst()
        }
        warnings.append("missing or unexpected header — first row treated as data")
        return lines[lines.indices]
    }

    private static func parseRow(
        _ line: Substring,
        row: Int,
        warnings: inout [String]
    ) -> Block? {
        let parts = line.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: false)
            .map(String.init)
        guard parts.count == 4 else {
            warnings.append("row \(row): expected 4 columns, got \(parts.count)")
            return nil
        }
        let title = parts[0].trimmingCharacters(in: .whitespaces)
        let categoryRaw = parts[1].trimmingCharacters(in: .whitespaces).lowercased()
        guard let start = Int(parts[2].trimmingCharacters(in: .whitespaces)),
              let duration = Int(parts[3].trimmingCharacters(in: .whitespaces))
        else {
            warnings.append("row \(row): startMinutes/durationMinutes must be integers")
            return nil
        }
        guard !title.isEmpty else {
            warnings.append("row \(row): title empty — skipped")
            return nil
        }
        guard duration > 0 else {
            warnings.append("row \(row): duration must be > 0 — skipped")
            return nil
        }
        let category = BlockCategory(rawValue: categoryRaw) ?? {
            warnings.append("row \(row): unknown category '\(categoryRaw)' — fell back to hygiene")
            return .hygiene
        }()
        return Block(
            title: title,
            category: category,
            startMinutesFromMidnight: max(0, min(24 * 60 - 1, start)),
            durationMinutes: duration
        )
    }
}
