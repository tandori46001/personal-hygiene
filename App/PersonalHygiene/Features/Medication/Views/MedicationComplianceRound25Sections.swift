import SwiftUI
import UIKit

/// Round-25 sections that wire round-24 medication helpers into the
/// compliance view:
/// - T2.11 30-day chart section.
/// - T2.12 streak row (current + best) using `MedicationStreakCounter`.
/// - T2.13 export 30-day dose history as CSV (clipboard).
extension MedicationComplianceView {

    @ViewBuilder
    func round25MonthlyChartSection(history: [MedicationDoseHistory.Entry]) -> some View {
        if !history.isEmpty {
            let cal = Calendar.autoupdatingCurrent
            let today = cal.startOfDay(for: Date())
            let dayKeys: [Date] = (0..<30).reversed().compactMap {
                cal.date(byAdding: .day, value: -$0, to: today)
            }
            let took: Set<Date> = Set(history.map { cal.startOfDay(for: $0.completedAt) })
            let points = dayKeys.map { day in
                Medication30DayChartView.DataPoint(day: day, took: took.contains(day))
            }
            Section {
                Medication30DayChartView(dataPoints: points)
            } header: {
                Text("medication.section.thirtyDayChart", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func round25StreakSection(history: [MedicationDoseHistory.Entry]) -> some View {
        let cal = Calendar.autoupdatingCurrent
        let dayKeys: Set<String> = Set(
            history.map { entry in
                MedicationStreakCounter.dayKey(entry.completedAt, calendar: cal)
            }
        )
        let current = MedicationStreakCounter.currentStreak(completionDays: dayKeys, calendar: cal)
        let best = MedicationStreakCounter.bestStreak(completionDays: dayKeys, calendar: cal)
        if best > 0 {
            Section {
                MedicationStreakCaption(currentStreak: current, bestStreak: best)
            } header: {
                Text("medication.section.streak", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func round25ExportRow(history: [MedicationDoseHistory.Entry]) -> some View {
        if !history.isEmpty {
            Section {
                Button {
                    UIPasteboard.general.string = MedicationDoseHistoryCSV.render(history)
                } label: {
                    Label {
                        Text("medication.export.csv30d", bundle: .main)
                    } icon: {
                        Image(systemName: "doc.on.clipboard")
                    }
                }
            } footer: {
                Text("medication.export.csv30d.footer", bundle: .main)
            }
        }
    }
}
