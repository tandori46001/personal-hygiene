import SwiftUI

/// Round-13 sections of `DiagnosticsView` — snapshot history, auth timeline,
/// network counts, pending details, refresh-trace export. Hosted in their
/// own extension to keep type-body lengths under SwiftLint's cap.
extension DiagnosticsView {

    @ViewBuilder
    var snapshotHistorySection: some View {
        if !snapshotHistory.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $snapshotHistoryExpanded) {
                    ForEach(Array(snapshotHistory.enumerated()), id: \.offset) { _, snap in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: snap.snapshotAt.formatted(date: .abbreviated, time: .standard))
                                .font(.caption.monospacedDigit())
                            Text(verbatim:
                                "build \(snap.commitSHA)"
                                + " · pending \(snap.pendingCount)"
                                + " · widgets \(snap.widgetReloadCount)"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    HStack {
                        Text("settings.diagnostics.section.snapshotHistory", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(snapshotHistory.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var authTimelineSection: some View {
        if !authTimeline.isEmpty {
            Section {
                ForEach(authTimeline) { entry in
                    HStack {
                        Text(verbatim: entry.statusRawValue)
                            .font(.caption.monospacedDigit())
                        Spacer()
                        Text(verbatim: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("settings.diagnostics.section.authTimeline", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var networkActivitySection: some View {
        if !networkCounts.isEmpty {
            Section {
                ForEach(NetworkActivityCounter.Source.allCases, id: \.self) { src in
                    let count = networkCounts[src] ?? 0
                    if count > 0 {
                        HStack {
                            Text(verbatim: src.rawValue)
                                .font(.caption)
                            Spacer()
                            Text(verbatim: "\(count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            } header: {
                Text("settings.diagnostics.section.networkActivity", bundle: .main)
            } footer: {
                Text("settings.diagnostics.section.networkActivity.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var pendingDetailsSection: some View {
        if !pendingDetails.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $pendingDetailsExpanded) {
                    ForEach(Array(pendingDetails.enumerated()), id: \.offset) { _, detail in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: detail.identifier)
                                .font(.caption2.monospacedDigit())
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if let date = detail.triggerDate {
                                Text(verbatim: date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    HStack {
                        Text("settings.diagnostics.section.pendingDetails", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(pendingDetails.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
