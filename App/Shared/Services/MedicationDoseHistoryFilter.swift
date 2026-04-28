import Foundation

/// Round-25 slice T3.19: window-based filter for `MedicationDoseHistory`
/// — picks the trailing 7d / 30d / 90d slice. Pure helper so the dose
/// history view + CSV exporter share the windowing logic.
public enum MedicationDoseHistoryFilter {

    public enum Window: Int, CaseIterable, Sendable {
        case sevenDays = 7
        case thirtyDays = 30
        case ninetyDays = 90
    }

    public static func filter(
        _ entries: [MedicationDoseHistory.Entry],
        window: Window,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [MedicationDoseHistory.Entry] {
        let cutoff = calendar.date(byAdding: .day, value: -window.rawValue, to: now)
            ?? now.addingTimeInterval(-Double(window.rawValue * 86_400))
        return entries.filter { $0.completedAt >= cutoff }
    }
}
