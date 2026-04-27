import SwiftUI

/// Round-10 sections of `DiagnosticsView`, hosted in an extension to keep
/// the main view's struct body under the SwiftLint type-body-length cap.
extension DiagnosticsView {

    @ViewBuilder
    var scheduleHealthSection: some View {
        Section {
            if let diff = scheduleDiff {
                row(
                    label: "settings.diagnostics.schedule.expected",
                    value: String(diff.expected)
                )
                row(
                    label: "settings.diagnostics.schedule.pending",
                    value: String(diff.pending)
                )
                let delta = diff.pending - diff.expected
                row(
                    label: "settings.diagnostics.schedule.diff",
                    value: delta == 0 ? "✓" : "Δ \(delta)"
                )
            } else {
                Text("settings.diagnostics.schedule.computing", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("settings.diagnostics.section.schedule", bundle: .main)
        } footer: {
            Text("settings.diagnostics.section.schedule.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var refreshTraceSection: some View {
        Section {
            if refreshTrace.isEmpty {
                Text("settings.diagnostics.refreshTrace.empty", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(refreshTrace.enumerated()), id: \.offset) { _, entry in
                    HStack {
                        Image(
                            systemName: entry.kind == RefreshTraceKind.reschedule
                                ? "arrow.left.arrow.right"
                                : "arrow.clockwise"
                        )
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                        Text(verbatim: entry.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.caption.monospacedDigit())
                        Spacer()
                        Text(verbatim: "\(entry.scheduledCount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Text("settings.diagnostics.section.refreshTrace", bundle: .main)
        }
    }

    @ViewBuilder
    var observabilitySection: some View {
        Section {
            row(
                label: "settings.diagnostics.observ.widgetReloads",
                value: String(widgetReloadCount)
            )
            row(
                label: "settings.diagnostics.observ.medObserver.available",
                value: observerSnapshot.available ? "✓" : "—"
            )
            row(
                label: "settings.diagnostics.observ.medObserver.identifiers",
                value: String(observerSnapshot.identifiers.count)
            )
            row(
                label: "settings.diagnostics.observ.tripDocs",
                value: String(tripDocumentCount)
            )
        } header: {
            Text("settings.diagnostics.section.observability", bundle: .main)
        }
    }
}
