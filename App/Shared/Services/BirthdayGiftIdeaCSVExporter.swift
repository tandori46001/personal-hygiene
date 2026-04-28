import Foundation

/// Round-21 slice T6.31: exports the entire gift-idea dictionary as a CSV
/// table — one row per `(contactID, idea)` pair — so the user can paste the
/// list into a spreadsheet or share it as plain text. Idea fields are
/// quoted when they contain commas or newlines.
public enum BirthdayGiftIdeaCSVExporter {

    public static func render(
        dictionary: [String: String] = BirthdayIdeaStore.dictionary()
    ) -> String {
        var lines = ["contactID,idea"]
        let sortedKeys = dictionary.keys.sorted()
        for key in sortedKeys {
            guard let raw = dictionary[key] else { continue }
            let idea = sanitize(raw)
            lines.append("\(key),\(idea)")
        }
        return lines.joined(separator: "\n")
    }

    static func sanitize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let needsQuoting = trimmed.contains(",") || trimmed.contains("\n") || trimmed.contains("\"")
        guard needsQuoting else { return trimmed }
        let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
