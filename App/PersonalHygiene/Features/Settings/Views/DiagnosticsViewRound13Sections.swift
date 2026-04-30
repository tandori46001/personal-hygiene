import SwiftUI
import UIKit

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
                    if snapshotHistory.count >= 2 {
                        Button {
                            // Round-19 slice T3.12: copy a one-line diff
                            // (newest vs second-newest) so the user can paste
                            // it into a bug report without grepping JSON.
                            let newer = snapshotHistory[0]
                            let older = snapshotHistory[1]
                            let diff = DiagnosticsSnapshot.diff(from: older, to: newer)
                            UIPasteboard.general.string = diff.formatted()
                        } label: {
                            Label {
                                Text("settings.diagnostics.snapshotDiff.copy", bundle: .main)
                            } icon: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
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
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(verbatim: src.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text(verbatim: "\(count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            // Round 31 (O02/O03): when any non-success
                            // outcome has been recorded for this source,
                            // show a one-line breakdown so the user can
                            // tell rate-limit hits from server errors from
                            // network failures.
                            if NetworkActivityCounter.shared.hasFailureOutcome(for: src) {
                                Text(verbatim: outcomeSummary(for: src))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
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

    /// Builds a `429:N · 5xx:N · net:N · dec:N` summary, omitting outcomes
    /// with zero count. Used by `networkActivitySection` to surface the
    /// rate-limit signal called out in the round-30 ALL OK? §D flag.
    private func outcomeSummary(for src: NetworkActivityCounter.Source) -> String {
        let outcomes = NetworkActivityCounter.shared.outcomes(for: src)
        var parts: [String] = []
        let rl = outcomes[.rateLimited, default: 0]
        if rl > 0 { parts.append("429:\(rl)") }
        let se = outcomes[.serverError, default: 0]
        if se > 0 { parts.append("5xx:\(se)") }
        let ne = outcomes[.networkError, default: 0]
        if ne > 0 { parts.append("net:\(ne)") }
        let de = outcomes[.decodingError, default: 0]
        if de > 0 { parts.append("dec:\(de)") }
        return parts.joined(separator: " · ")
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
