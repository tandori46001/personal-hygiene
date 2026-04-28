import Charts
import SwiftUI

/// Round-21 slice T2.8: 30-day mood trend rendered with Swift Charts. Plots
/// the daily average mood score (1=awful, 5=great); empty days appear as
/// gaps so the user can see streaks of disengagement.
struct MoodTrendChartView: View {

    let bins: [MoodTrendAggregator.DailyBin]

    var body: some View {
        Chart(scoredBins, id: \.day) { bin in
            LineMark(
                x: .value("day", bin.day),
                y: .value("score", bin.score ?? 0)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(.tint)
            PointMark(
                x: .value("day", bin.day),
                y: .value("score", bin.score ?? 0)
            )
            .symbolSize(28)
            .foregroundStyle(.tint)
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 3, 5]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text(verbatim: emoji(for: score))
                    }
                }
            }
        }
        .frame(height: 140)
        .accessibilityLabel(Text("settings.moodLog.trend.a11y", bundle: .main))
    }

    private var scoredBins: [MoodTrendAggregator.DailyBin] {
        bins.filter { $0.score != nil }
    }

    private func emoji(for score: Int) -> String {
        switch score {
        case 5: MoodLogStore.Mood.great.emoji
        case 4: MoodLogStore.Mood.good.emoji
        case 3: MoodLogStore.Mood.okay.emoji
        case 2: MoodLogStore.Mood.bad.emoji
        default: MoodLogStore.Mood.awful.emoji
        }
    }
}
