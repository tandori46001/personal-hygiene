import SwiftUI
import UIKit

/// Round-21 SettingsView wires:
/// - T2.8 `moodTrendSection`: 30-day trend chart under the existing mood log
///   disclosure.
/// - T2.10 `moodFilterPicker`: filter the disclosure list by emoji.
/// - T2.11 `moodWeeklyGoalSection`: stepper to set "X good days / week" goal,
///   surfaces a `3 / 5` style caption alongside the bare count.
/// - T2.12 `localizedMoodCSVCopyRow`: copy-CSV variant whose header respects
///   the user's locale.
extension SettingsView {

    @ViewBuilder
    var moodTrendSection: some View {
        let bins = MoodTrendAggregator.bins(from: MoodLogStore.entries())
        let hasData = bins.contains { $0.score != nil }
        if hasData {
            Section {
                MoodTrendChartView(bins: bins)
            } header: {
                Text("settings.moodLog.trend.title", bundle: .main)
            } footer: {
                Text("settings.moodLog.trend.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var moodWeeklyGoalSection: some View {
        Section {
            let goalBinding = Binding<Int>(
                get: { MoodWeeklyGoalStore.goal() },
                set: { MoodWeeklyGoalStore.setGoal($0) }
            )
            Stepper(value: goalBinding, in: MoodWeeklyGoalStore.allowedRange) {
                let goal = goalBinding.wrappedValue
                if goal == 0 {
                    Text("settings.moodLog.goal.none", bundle: .main)
                } else {
                    Text("settings.moodLog.goal.value \(goal)", bundle: .main)
                }
            }
            if MoodWeeklyGoalStore.isActive() {
                let progress = MoodLogStore.goodDaysCount()
                Text("settings.moodLog.goal.progress \(progress) \(MoodWeeklyGoalStore.goal())", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("settings.moodLog.goal.title", bundle: .main)
        } footer: {
            Text("settings.moodLog.goal.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var localizedMoodCSVCopyRow: some View {
        Section {
            Button {
                UIPasteboard.general.string = MoodLogStore.exportLocalizedCSV()
            } label: {
                Label {
                    Text("settings.moodLog.exportLocalizedCSV", bundle: .main)
                } icon: {
                    Image(systemName: "doc.on.doc.fill")
                }
            }
        } footer: {
            Text("settings.moodLog.exportLocalizedCSV.footer", bundle: .main)
        }
    }

    /// Round-21 slice T2.10: filter the existing mood log disclosure by
    /// emoji. Stored in `@State` on the host view; this provides the picker
    /// row that mutates the filter binding.
    @ViewBuilder
    func moodFilterPicker(selection: Binding<String?>) -> some View {
        Picker(selection: selection) {
            Text("settings.moodLog.filter.all", bundle: .main).tag(String?.none)
            ForEach(MoodLogStore.Mood.allCases, id: \.rawValue) { mood in
                Text(verbatim: mood.emoji).tag(Optional(mood.rawValue))
            }
        } label: {
            Text("settings.moodLog.filter.label", bundle: .main)
        }
        .pickerStyle(.segmented)
    }
}
