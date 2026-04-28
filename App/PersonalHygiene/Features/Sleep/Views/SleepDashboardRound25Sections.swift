import SwiftUI

/// Round-25 sections that wire round-24 sleep helpers into the dashboard:
/// - T2.9 weekly average chart + delta caption.
/// - T2.10 bedtime variance verdict caption.
/// - T2.14 share-as-image button (PNG of the weekly delta card).
/// All sections render gracefully when input data is empty.
extension SleepDashboardView {

    @ViewBuilder
    func round25WeeklyAverageSection(nights: [SleepNight]) -> some View {
        if !nights.isEmpty {
            Section {
                SleepWeeklyAverageChart(
                    dataPoints: nights.map { night in
                        SleepWeeklyAverageChart.DataPoint(
                            day: night.nightOf,
                            hours: Double(night.durationMinutes) / 60.0
                        )
                    }
                )
                if let summary = SleepWeeklyDelta.summarize(
                    log: nights.map {
                        SleepWeeklyDelta.DailySleep(
                            day: $0.nightOf,
                            durationMinutes: $0.durationMinutes
                        )
                    }
                ) {
                    SleepWeeklyDeltaCaption(summary: summary)
                }
            } header: {
                Text("sleep.section.weeklyAverage", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func round25BedtimeVarianceSection(bedtimeMinutes: [Int]) -> some View {
        if let summary = SleepBedtimeVariance.summarize(bedtimeMinutes: bedtimeMinutes) {
            let verdict = SleepBedtimeVariance.verdict(stddevMinutes: summary.stddev)
            Section {
                LabeledContent {
                    Text(verbatim: String(format: "%.0f min", summary.stddev))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(verdictColor(verdict))
                } label: {
                    Text("sleep.bedtime.variance.label", bundle: .main)
                }
                Text(verdictKey(verdict), bundle: .main)
                    .font(.caption)
                    .foregroundStyle(verdictColor(verdict))
            } header: {
                Text("sleep.bedtime.variance.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func round25ShareDeltaSection(nights: [SleepNight], onShareImage: @escaping (Data) -> Void) -> some View {
        if let summary = SleepWeeklyDelta.summarize(
            log: nights.map {
                SleepWeeklyDelta.DailySleep(
                    day: $0.nightOf,
                    durationMinutes: $0.durationMinutes
                )
            }
        ) {
            Section {
                Button {
                    if let png = SleepWeeklyDeltaImageRenderer.render(summary) {
                        onShareImage(png)
                    }
                } label: {
                    Label {
                        Text("sleep.weeklyDelta.shareImage", bundle: .main)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func verdictColor(_ verdict: SleepBedtimeVariance.Verdict) -> Color {
        switch verdict {
        case .consistent: return .green
        case .driftSlight: return .orange
        case .driftSignificant: return .red
        }
    }

    private func verdictKey(_ verdict: SleepBedtimeVariance.Verdict) -> LocalizedStringKey {
        switch verdict {
        case .consistent: return "sleep.bedtime.verdict.consistent"
        case .driftSlight: return "sleep.bedtime.verdict.driftSlight"
        case .driftSignificant: return "sleep.bedtime.verdict.driftSignificant"
        }
    }
}
