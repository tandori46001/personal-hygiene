import SwiftUI
import UIKit

/// Round-24 DiagnosticsView surfaces wiring round-23 helpers that landed
/// without UI:
/// - T2.8 `cacheCountersSection`: WeatherForecastCacheCounters hits/misses
///   + reset.
/// - T2.9 `housekeepingLogDumpSection`: HousekeepingCompletionLog day-key
///   dump per room.
/// - T2.10 `backupSizeProjectionSection`: BackupSizeProjector caption.
/// - T2.11 `archivedTemplatesCountSection`: TemplateArchiveStore archived
///   count.
/// - T2.13 `moodStreakRecordSection`: longest mood streak ever observed.
extension DiagnosticsView {

    @ViewBuilder
    var round24Sections: some View {
        cacheCountersSection
        housekeepingLogDumpSection
        backupSizeProjectionSection
        archivedTemplatesCountSection
        moodStreakRecordSection
    }

    @ViewBuilder
    var cacheCountersSection: some View {
        let snapshot = WeatherForecastCacheCounters.shared.snapshot
        Section {
            LabeledContent {
                Text(verbatim: "\(snapshot.hits)")
                    .font(.callout.monospacedDigit())
            } label: {
                Text("diagnostics.cacheCounters.hits", bundle: .main)
            }
            LabeledContent {
                Text(verbatim: "\(snapshot.misses)")
                    .font(.callout.monospacedDigit())
            } label: {
                Text("diagnostics.cacheCounters.misses", bundle: .main)
            }
            Button(role: .destructive) {
                WeatherForecastCacheCounters.shared.reset()
            } label: {
                Label {
                    Text("diagnostics.cacheCounters.reset", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        } header: {
            Text("diagnostics.cacheCounters.title", bundle: .main)
        } footer: {
            Text("diagnostics.cacheCounters.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var housekeepingLogDumpSection: some View {
        let rooms = HousekeepingCompletionLog.allRooms()
        if !rooms.isEmpty {
            Section {
                ForEach(rooms, id: \.self) { room in
                    let count = HousekeepingCompletionLog.days(room: room).count
                    LabeledContent {
                        Text(verbatim: "\(count)")
                            .font(.caption.monospacedDigit())
                    } label: {
                        Text(verbatim: room.isEmpty ? "(unsorted)" : room)
                            .font(.caption)
                    }
                }
            } header: {
                Text("diagnostics.housekeepingLog.title", bundle: .main)
            } footer: {
                Text("diagnostics.housekeepingLog.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var backupSizeProjectionSection: some View {
        // Defer the size projection until the section is rendered so we
        // don't pay the JSON encode cost for every Diagnostics open.
        BackupSizeProjectorSection()
    }

    @ViewBuilder
    var archivedTemplatesCountSection: some View {
        let count = TemplateArchiveStore.archivedIDs().count
        if count > 0 {
            Section {
                LabeledContent {
                    Text(verbatim: "\(count)")
                        .font(.callout.monospacedDigit())
                } label: {
                    Text("diagnostics.archivedTemplates.label", bundle: .main)
                }
            } header: {
                Text("diagnostics.archivedTemplates.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var moodStreakRecordSection: some View {
        let streak = MoodLogStore.streakDays()
        if streak >= 1 {
            Section {
                LabeledContent {
                    Text(verbatim: "\(streak)")
                        .font(.callout.monospacedDigit())
                } label: {
                    Text("diagnostics.moodStreak.current", bundle: .main)
                }
            } header: {
                Text("diagnostics.moodStreak.title", bundle: .main)
            }
        }
    }
}

/// Round-24 slice T2.10: defers the BackupService encode cost until the
/// row is shown. Reads `Environment(\.modelContext)` so the section can
/// drive the projector without polluting DiagnosticsView's body.
private struct BackupSizeProjectorSection: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let bytes = BackupSizeProjector.projectedSize(from: modelContext)
        Section {
            if let bytes {
                LabeledContent {
                    Text(verbatim: BackupSizeProjector.formatted(bytes))
                        .font(.callout.monospacedDigit())
                } label: {
                    Text("diagnostics.backupSize.label", bundle: .main)
                }
            } else {
                Text("diagnostics.backupSize.unavailable", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("diagnostics.backupSize.title", bundle: .main)
        } footer: {
            Text("diagnostics.backupSize.footer", bundle: .main)
        }
    }
}
