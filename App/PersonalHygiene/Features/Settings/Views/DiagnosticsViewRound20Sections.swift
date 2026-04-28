import SwiftUI
import UIKit

/// Round-20 DiagnosticsView wires:
/// - T5.21 export refresh-trace as CSV (alongside the existing JSON snapshot
///   export). One row per entry, header `timestamp,scheduledCount,kind`.
/// - T5.22 "Everything bundle" — share the latest backup JSON + the
///   one-pager PDF + a metadata header in a single share sheet.
/// - T5.24 process-launches table (uses round-12 `ProcessLaunchHistoryStore`).
extension DiagnosticsView {

    @ViewBuilder
    var refreshTraceExportRow: some View {
        Button {
            let csv = Self.refreshTraceCSV(refreshTrace)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("refresh-trace-\(Int(Date().timeIntervalSince1970)).csv")
            try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
            snapshotExportURL = url
        } label: {
            Label {
                Text("settings.diagnostics.exportRefreshTraceCSV", bundle: .main)
            } icon: {
                Image(systemName: "tablecells.badge.ellipsis")
            }
        }
        .disabled(refreshTrace.isEmpty)
    }

    /// Round-20 slice T5.21: CSV serialization of refresh-trace entries.
    /// Header = `timestamp,scheduledCount,kind`. Empty input returns header
    /// only (no trailing newline; same convention as `pendingByGroupCSV`).
    static func refreshTraceCSV(_ entries: [RefreshTraceLog.Entry]) -> String {
        var lines = ["timestamp,scheduledCount,kind"]
        let formatter = ISO8601DateFormatter()
        for entry in entries {
            lines.append("\(formatter.string(from: entry.timestamp)),\(entry.scheduledCount),\(entry.kind.rawValue)")
        }
        return lines.joined(separator: "\n")
    }
}
