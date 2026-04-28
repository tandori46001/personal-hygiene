import SwiftUI

/// Round-25 slice T6.40: tiny glance view that shows current + best
/// medication streak. Reads completion-day keys from the shared App
/// Group store; falls back to nothing when no medication has been logged.
struct WatchMedicationStreakGlance: View {

    let completionDayKeys: Set<String>

    var body: some View {
        let current = MedicationStreakCounter.currentStreak(completionDays: completionDayKeys)
        let best = MedicationStreakCounter.bestStreak(completionDays: completionDayKeys)
        if best > 0 {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("watch.medication.streak.current", bundle: .main)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "\(current)")
                        .font(.system(.title3, design: .rounded).monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("watch.medication.streak.best", bundle: .main)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(verbatim: "\(best)")
                        .font(.system(.body, design: .rounded).monospacedDigit())
                        .foregroundStyle(.green)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
