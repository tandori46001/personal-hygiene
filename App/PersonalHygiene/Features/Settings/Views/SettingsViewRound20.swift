import SwiftUI
import UIKit

/// Round-20 SettingsView wires:
/// - T2.8 `moodLogSection`: disclosure listing the last 30 mood entries
///   with timestamp + emoji.
/// - T2.9 destructive "Clear mood log" button below the disclosure.
/// - T2.11 "Export mood log (CSV)" share button.
/// - T5.22 "Export everything bundle" — copies a multi-section text bundle
///   covering build descriptor + locale + key counts + last mood + last
///   diagnostics snapshot identifier to the clipboard.
extension SettingsView {

    @ViewBuilder
    var everythingBundleRow: some View {
        Section {
            Button {
                UIPasteboard.general.string = Self.everythingBundleText()
            } label: {
                Label {
                    Text("settings.everythingBundle.action", bundle: .main)
                } icon: {
                    Image(systemName: "shippingbox")
                }
            }
        } footer: {
            Text("settings.everythingBundle.footer", bundle: .main)
        }
    }

    /// Round-20 slice T5.22: assembles a single text payload covering the
    /// pieces a triager would otherwise have to copy individually:
    /// - build descriptor (version + commit SHA)
    /// - locale + i18n key count
    /// - mood log size + last entry timestamp
    /// - diagnostics snapshot history size
    /// - mood log CSV (compact)
    static func everythingBundleText() -> String {
        let moodEntries = MoodLogStore.entries()
        let snapshotCount = SnapshotHistoryStore.snapshots().count
        let lastMoodSummary: String = moodEntries.first.map {
            "\($0.recordedAt.formatted(date: .abbreviated, time: .shortened)) · \($0.moodCase?.emoji ?? "?")"
        } ?? "(none)"
        let lines: [String] = [
            "## personal-hygiene — everything bundle",
            "build: \(BuildInfo.shortDescriptor)",
            "locale: \(Locale.current.identifier) · keys: \(LocalizationKeyCount.total)",
            "mood entries: \(moodEntries.count) · last: \(lastMoodSummary)",
            "diagnostics snapshots retained: \(snapshotCount)",
            "",
            "## mood log",
            MoodLogStore.exportCSV(),
        ]
        return lines.joined(separator: "\n")
    }

    @ViewBuilder
    var moodLogSection: some View {
        let entries = MoodLogStore.entries()
        Section {
            DisclosureGroup {
                if entries.isEmpty {
                    Text("settings.moodLog.empty", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        HStack {
                            Text(verbatim: entry.moodCase?.emoji ?? "•")
                                .font(.body)
                            Text(verbatim: entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            } label: {
                HStack {
                    Text("settings.moodLog.title", bundle: .main)
                    Spacer()
                    Text(verbatim: "\(entries.count)")
                        .foregroundStyle(.secondary)
                }
            }
            if !entries.isEmpty {
                Button {
                    UIPasteboard.general.string = MoodLogStore.exportCSV()
                } label: {
                    Label {
                        Text("settings.moodLog.exportCSV", bundle: .main)
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                }
                Button(role: .destructive) {
                    MoodLogStore.clear()
                } label: {
                    Label {
                        Text("settings.moodLog.clear", bundle: .main)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            }
        } footer: {
            Text("settings.moodLog.footer", bundle: .main)
        }
    }
}
