import Foundation

/// Round-23 slice T3.18: parses a CSV where each row carries a single
/// day's trip notes (`day,note`) and produces a Markdown bullet list ready
/// to append to `Trip.notes`. Pure helper — caller decides what to do with
/// the result.
public enum TripNotesCSVImporter {

    public static let header = "day,note"

    public struct ParseResult: Equatable {
        public let markdown: String
        public let warnings: [String]
    }

    public static func parse(_ csv: String) -> ParseResult {
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        guard !lines.isEmpty else {
            return ParseResult(markdown: "", warnings: ["empty input"])
        }
        var warnings: [String] = []
        let dataLines: ArraySlice<Substring>
        if lines[0].trimmingCharacters(in: .whitespaces).lowercased() == header {
            dataLines = lines.dropFirst()
        } else {
            warnings.append("missing header — first row treated as data")
            dataLines = lines[lines.indices]
        }
        var markdownLines: [String] = []
        for (offset, line) in dataLines.enumerated() {
            let parts = line.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                .map(String.init)
            guard parts.count == 2 else {
                warnings.append("row \(offset + 1): expected 2 columns")
                continue
            }
            let day = parts[0].trimmingCharacters(in: .whitespaces)
            let note = parts[1].trimmingCharacters(in: .whitespaces)
            guard !day.isEmpty, !note.isEmpty else {
                warnings.append("row \(offset + 1): empty day or note — skipped")
                continue
            }
            markdownLines.append("- **\(day)** — \(note)")
        }
        return ParseResult(markdown: markdownLines.joined(separator: "\n"), warnings: warnings)
    }
}
