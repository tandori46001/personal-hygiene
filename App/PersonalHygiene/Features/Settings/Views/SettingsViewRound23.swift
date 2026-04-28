import SwiftUI
import UIKit

/// Round-23 SettingsView wires for the new mood log surfaces:
/// - T2.8 `moodSectionedDisclosure`: groups entries by day instead of flat.
/// - T2.9 `moodTodayOnlyToggle`: filter shortcut for the disclosure.
/// - T2.10 `moodHistogramSection`: bar chart per emoji.
/// - T2.11 `streakShareSection`: render today's streak as PNG + share.
/// - T2.12 `moodHeatmapSection`: 6×7 calendar heatmap.
extension SettingsView {

    @ViewBuilder
    var round23Sections: some View {
        moodSectionedDisclosure
        moodHistogramSection
        moodHeatmapSection
        streakShareSection
        resetAllCachesRow
    }

    /// Round-24 slice T2.12: surface for `CacheResetter.resetAll()`.
    /// Mood log + weekly goal are intentionally untouched
    /// (`CacheResetterPreservesMoodTests` guards).
    @ViewBuilder
    var resetAllCachesRow: some View {
        Section {
            Button(role: .destructive) {
                CacheResetter.resetAll()
            } label: {
                Label {
                    Text("settings.caches.resetAll", bundle: .main)
                } icon: {
                    Image(systemName: "trash.slash")
                }
            }
        } footer: {
            Text("settings.caches.resetAll.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var moodSectionedDisclosure: some View {
        let allEntries = MoodLogStore.entries()
        let sections = MoodLogGrouping.sections(from: allEntries)
        if !sections.isEmpty {
            Section {
                DisclosureGroup {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        let formatted = section.day.formatted(date: .abbreviated, time: .omitted)
                        Section {
                            ForEach(Array(section.entries.enumerated()), id: \.offset) { _, entry in
                                HStack {
                                    Text(verbatim: entry.moodCase?.emoji ?? "•")
                                    Text(verbatim: entry.recordedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .accessibilityElement(children: .combine)
                            }
                        } header: {
                            Text(verbatim: formatted)
                                .font(.caption)
                        }
                    }
                } label: {
                    HStack {
                        Text("settings.moodLog.sections.title", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(sections.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("settings.moodLog.sections.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var moodHistogramSection: some View {
        let bins = MoodHistogram.bins(from: MoodLogStore.entries())
        // swiftlint:disable:next empty_count
        if bins.contains(where: { $0.count > 0 }) {
            Section {
                MoodHistogramChartView(bins: bins)
            } header: {
                Text("settings.moodLog.histogram.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var moodHeatmapSection: some View {
        let rows = MoodHeatmapAggregator.rows(from: MoodLogStore.entries(), weeks: 6)
        let hasAny = rows.contains { row in
            row.cells.contains { cell in cell?.score != nil }
        }
        if hasAny {
            Section {
                MoodHeatmapView(rows: rows)
            } header: {
                Text("settings.moodLog.heatmap.title", bundle: .main)
            } footer: {
                Text("settings.moodLog.heatmap.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var streakShareSection: some View {
        let streak = MoodLogStore.streakDays()
        if streak >= 3 {
            Section {
                Button {
                    if let png = StreakImageRenderer.renderStreak(days: streak),
                       let image = UIImage(data: png) {
                        UIPasteboard.general.image = image
                    }
                } label: {
                    Label {
                        Text("settings.moodLog.streak.share", bundle: .main)
                    } icon: {
                        Image(systemName: "square.and.arrow.up.on.square")
                    }
                }
            } footer: {
                Text("settings.moodLog.streak.share.footer", bundle: .main)
            }
        }
    }
}
