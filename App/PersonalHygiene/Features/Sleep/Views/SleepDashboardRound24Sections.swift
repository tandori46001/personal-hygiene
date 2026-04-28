import Charts
import SwiftUI

/// Round-24 slice T3.14: weekly average bar chart on SleepDashboardView.
/// Pure SwiftUI; takes a per-day duration log and renders a Charts BarMark
/// per weekday. Renders nothing when the log is empty.
struct SleepWeeklyAverageChart: View {

    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Date
        let hours: Double
    }

    let dataPoints: [DataPoint]

    var body: some View {
        if !dataPoints.isEmpty {
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("day", point.day, unit: .day),
                    y: .value("hours", point.hours)
                )
                .foregroundStyle(.indigo)
            }
            .frame(height: 140)
            .accessibilityLabel(Text("sleep.weeklyAverage.a11y", bundle: .main))
        }
    }
}

/// Round-24 slice T3.15: caption rendering `SleepWeeklyDelta.Summary` as
/// "+25 min vs last week" / "−10 min vs last week" / "≈ same".
struct SleepWeeklyDeltaCaption: View {
    let summary: SleepWeeklyDelta.Summary

    private var symbol: String {
        let delta = summary.delta
        return delta > 5 ? "↑" : (delta < -5 ? "↓" : "→")
    }

    private var formattedDelta: String {
        String(format: "%+.0f min", summary.delta)
    }

    var body: some View {
        Text(
            "sleep.weeklyDelta.caption \(symbol) \(formattedDelta)",
            bundle: .main
        )
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }
}
