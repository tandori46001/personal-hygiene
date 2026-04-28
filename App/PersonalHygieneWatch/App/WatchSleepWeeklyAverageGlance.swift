import SwiftUI

/// Round-25 slice T6.39: tiny glance view embedded in the watch settings
/// page that shows the trailing weekly sleep average + delta caption.
/// Reads from the shared App Group's `SleepWeeklyAverageStore` (TBD —
/// for now uses an empty input and renders nothing).
struct WatchSleepWeeklyAverageGlance: View {

    let nights: [SleepNight]

    var body: some View {
        if let summary = SleepWeeklyDelta.summarize(
            log: nights.map {
                SleepWeeklyDelta.DailySleep(
                    day: $0.nightOf,
                    durationMinutes: $0.durationMinutes
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 2) {
                Text("watch.sleep.weeklyAverage", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: String(format: "%.0f min", summary.thisWeekMinutes))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                Text(verbatim: String(format: "%+.0f vs prior", summary.delta))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(summary.delta >= 0 ? .green : .orange)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
