import Charts
import SwiftUI

/// Round-25 slice T3.20: rolling 30-day adherence line chart. Each point
/// is the trailing-7-day adherence ratio anchored on that day. Renders
/// alongside the existing 30-day binary bar chart on
/// `MedicationComplianceView`.
struct MedicationAdherence30dTrendChart: View {

    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Date
        let adherence: Double
    }

    let dataPoints: [DataPoint]

    var body: some View {
        if !dataPoints.isEmpty {
            Chart(dataPoints) { point in
                LineMark(
                    x: .value("day", point.day, unit: .day),
                    y: .value("adherence", point.adherence)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("day", point.day, unit: .day),
                    y: .value("adherence", point.adherence)
                )
                .foregroundStyle(.green.opacity(0.18))
            }
            .chartYScale(domain: 0...1)
            .frame(height: 100)
            .accessibilityLabel(Text("medication.adherence.trend.a11y", bundle: .main))
        }
    }

    static func dataPoints(
        from history: [MedicationDoseHistory.Entry],
        scheduledPerDay: Int = 1,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DataPoint] {
        let today = calendar.startOfDay(for: now)
        let dayBuckets: [Date] = (0..<30).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        let entryDays = history.map { calendar.startOfDay(for: $0.completedAt) }
        return dayBuckets.map { day in
            let windowEnd = day
            let windowStart = calendar.date(byAdding: .day, value: -6, to: day) ?? day
            let countInWindow = entryDays.filter { $0 >= windowStart && $0 <= windowEnd }.count
            let target = max(1, scheduledPerDay * 7)
            let adherence = min(1.0, Double(countInWindow) / Double(target))
            return DataPoint(day: day, adherence: adherence)
        }
    }
}
