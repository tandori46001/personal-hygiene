import SwiftUI

/// Round-22 slice T4.19: hosts the mood trend chart with a 7-day vs 30-day
/// toggle. Persists user preference via `@AppStorage` so the chart opens
/// in the same window the user last looked at.
struct MoodTrendSectionView: View {

    @AppStorage("settings.moodLog.trendWindowDays") private var windowDays: Int = 30

    private var bins: [MoodTrendAggregator.DailyBin] {
        MoodTrendAggregator.bins(from: MoodLogStore.entries(), days: windowDays)
    }

    var body: some View {
        let trendBins = bins
        let hasData = trendBins.contains { $0.score != nil }
        if hasData {
            Section {
                Picker(selection: $windowDays) {
                    Text("settings.moodLog.trend.window.7", bundle: .main).tag(7)
                    Text("settings.moodLog.trend.window.30", bundle: .main).tag(30)
                } label: {
                    Text("settings.moodLog.trend.window.label", bundle: .main)
                }
                .pickerStyle(.segmented)
                MoodTrendChartView(bins: trendBins)
                if let delta = MoodTrendAggregator.weeklyDelta(from: MoodLogStore.entries()) {
                    let symbol = delta > 0.05 ? "↑" : (delta < -0.05 ? "↓" : "→")
                    Text(
                        "settings.moodLog.trend.weeklyDelta \(symbol) \(formattedDelta(delta))",
                        bundle: .main
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("settings.moodLog.trend.title", bundle: .main)
            } footer: {
                Text("settings.moodLog.trend.footer", bundle: .main)
            }
        }
    }

    private func formattedDelta(_ value: Double) -> String {
        String(format: "%+.2f", value)
    }
}
