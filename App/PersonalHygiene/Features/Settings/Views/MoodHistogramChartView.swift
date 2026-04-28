import Charts
import SwiftUI

/// Round-23 slice T2.10: bar chart over `MoodHistogram.bins(...)` showing
/// the count per mood. Skipped entirely when every count is zero.
struct MoodHistogramChartView: View {

    let bins: [MoodHistogram.Bin]

    private var hasAnyData: Bool {
        // swiftlint:disable:next empty_count
        bins.contains { $0.count > 0 }
    }

    var body: some View {
        if hasAnyData {
            Chart(bins) { bin in
                BarMark(
                    x: .value("mood", bin.mood.emoji),
                    y: .value("count", bin.count)
                )
                .foregroundStyle(.tint)
            }
            .frame(height: 120)
            .accessibilityLabel(Text("settings.moodLog.histogram.a11y", bundle: .main))
        }
    }
}
