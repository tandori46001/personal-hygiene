import Charts
import SwiftUI

/// Round-24 slice T3.16: 30-day adherence chart variant. Each cell is one
/// day with a binary "took medication" mark. Slim ring chart appears on
/// `MedicationComplianceView` below the existing 7-day summary.
struct Medication30DayChartView: View {

    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Date
        let took: Bool
    }

    let dataPoints: [DataPoint]

    var body: some View {
        if !dataPoints.isEmpty {
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("day", point.day, unit: .day),
                    y: .value("took", point.took ? 1 : 0)
                )
                .foregroundStyle(point.took ? Color.green : Color.red.opacity(0.6))
            }
            .frame(height: 80)
            .chartYAxis(.hidden)
            .accessibilityLabel(Text("medication.thirtyDayChart.a11y", bundle: .main))
        }
    }
}

/// Round-24 slice T3.17: caption beneath the compliance dashboard showing
/// current and best adherence streaks.
struct MedicationStreakCaption: View {
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        if bestStreak > 0 {
            HStack {
                Text("medication.streak.current \(currentStreak)", bundle: .main)
                    .font(.caption.monospacedDigit())
                Spacer()
                Text("medication.streak.best \(bestStreak)", bundle: .main)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
