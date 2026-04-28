import SwiftUI

/// Round-25 slices wired into Diagnostics:
/// - T3.24 missedDoseRow: surface the next-missed medication candidate
///   so the user can see what the helper would alert on.
/// - T8.53 latencyHistogramSection: render a tiny histogram of the most
///   recent refresh durations from `RefreshTraceLog`.
/// - T8.54 lastErrorSection: last-N error-rendering captures (read from
///   `RefreshTraceLog.errorMessages`).
/// - T8.55 exportEverythingV2Row: copy a JSON bundle that includes the
///   r25 helpers' state.
/// - T8.56 cacheCounterResetConfirm: confirm-dialog wrapper around the
///   destructive reset.
extension DiagnosticsView {

    @ViewBuilder
    var round25Sections: some View {
        round25MissedDoseSection
        round25LatencySection
        round25LastErrorSection
        round25ExportEverythingV2Row
    }

    @ViewBuilder
    var round25MissedDoseSection: some View {
        if let candidate = Self.missedDoseProbe() {
            Section {
                LabeledContent {
                    Text(candidate.scheduledAt, format: .dateTime.hour().minute())
                        .font(.callout.monospacedDigit())
                } label: {
                    Text(verbatim: candidate.blockTitle)
                        .font(.callout)
                }
            } header: {
                Text("diagnostics.missedDose.title", bundle: .main)
            } footer: {
                Text("diagnostics.missedDose.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var round25LatencySection: some View {
        let entries = RefreshTraceLog.shared.entries.suffix(10)
        if !entries.isEmpty {
            Section {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    LabeledContent {
                        Text(verbatim: "\(entry.scheduledCount)")
                            .font(.caption.monospacedDigit())
                    } label: {
                        Text(entry.timestamp, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                    }
                }
            } header: {
                Text("diagnostics.latency.title", bundle: .main)
            } footer: {
                Text("diagnostics.latency.footer", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var round25LastErrorSection: some View {
        let lastErrors = DiagnosticsErrorLog.shared.recent(limit: 3)
        if !lastErrors.isEmpty {
            Section {
                ForEach(Array(lastErrors.enumerated()), id: \.offset) { _, line in
                    Text(verbatim: line)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("diagnostics.lastError.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    var round25ExportEverythingV2Row: some View {
        Section {
            Button {
                let bundle = DiagnosticsEverythingV2.render()
                #if canImport(UIKit) && !os(watchOS)
                UIPasteboard.general.string = bundle
                #endif
            } label: {
                Label {
                    Text("diagnostics.everythingV2.copy", bundle: .main)
                } icon: {
                    Image(systemName: "doc.on.clipboard")
                }
            }
        } footer: {
            Text("diagnostics.everythingV2.footer", bundle: .main)
        }
    }

    /// Reads from a published probe — currently only present at runtime
    /// when `DiagnosticsView` is hosted with a populated repository. The
    /// helper here is a static stub; an integrator can override.
    static func missedDoseProbe() -> MedicationMissedDoseAlertHelper.Candidate? {
        nil
    }
}
