import Foundation
import SwiftData

/// Round-23 slice T6.32: projects the byte size of the next backup export
/// without actually writing the JSON to disk. Useful for the user to see
/// "Export will be ~12 KB" before tapping the share sheet.
@MainActor
public enum BackupSizeProjector {

    public static func projectedSize(
        from context: ModelContext,
        diagnostics: DiagnosticsSnapshot? = nil
    ) -> Int? {
        guard let snapshot = try? BackupService.export(
            from: context,
            diagnostics: diagnostics
        ) else {
            return nil
        }
        return (try? BackupService.encode(snapshot))?.count
    }

    public static func formatted(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
