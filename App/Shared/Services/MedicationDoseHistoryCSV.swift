import Foundation

/// Round-25 slice T2.13: CSV exporter for `MedicationDoseHistory.Entry`.
/// Pairs with the new "Export 30-day dose history" row on
/// `MedicationComplianceView`. Headers in EN since the rest of the
/// medication CSV pipeline (dose history view, snapshot diffs) all stay
/// in English for tooling compatibility.
public enum MedicationDoseHistoryCSV {

    public static let header = "completed_at,block_title,concept_identifier"

    public static func render(_ entries: [MedicationDoseHistory.Entry]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let rows = entries.map { entry -> String in
            let title = escape(entry.blockTitle)
            let concept = escape(entry.conceptIdentifier ?? "")
            let completed = formatter.string(from: entry.completedAt)
            return "\(completed),\(title),\(concept)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
