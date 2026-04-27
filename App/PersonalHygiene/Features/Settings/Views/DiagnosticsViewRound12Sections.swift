import SwiftUI

/// Round-12 sections of `DiagnosticsView`. Hosted in a separate extension to
/// keep the type-body length per-file within SwiftLint caps.
extension DiagnosticsView {

    /// Round-12 slice 21: top-of-screen traffic-light badge aggregating
    /// schedule drift + observer state + auth status + widget reloads.
    @ViewBuilder
    var healthBadgeSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: healthIconName)
                    .font(.title3)
                    .foregroundStyle(healthIconColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(healthTitleKey, bundle: .main)
                        .font(.body.bold())
                    Text(healthSubtitleKey, bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var healthStatus: ObservabilityHealthCheck.Status {
        let routineDelta: Int = {
            guard let diff = scheduleDiff else { return 0 }
            return diff.pending - diff.expected
        }()
        let authOK = viewModel.status == .authorized || viewModel.status == .provisional
        return ObservabilityHealthCheck.status(
            routinePendingDelta: routineDelta,
            widgetReloads: widgetReloadCount,
            observerAvailable: observerSnapshot.available,
            authStatusOK: authOK
        )
    }

    private var healthIconName: String {
        switch healthStatus {
        case .green: "checkmark.circle.fill"
        case .yellow: "exclamationmark.triangle.fill"
        case .red: "xmark.octagon.fill"
        }
    }

    private var healthIconColor: Color {
        switch healthStatus {
        case .green: .green
        case .yellow: .orange
        case .red: .red
        }
    }

    private var healthTitleKey: LocalizedStringKey {
        switch healthStatus {
        case .green: "settings.diagnostics.health.title.green"
        case .yellow: "settings.diagnostics.health.title.yellow"
        case .red: "settings.diagnostics.health.title.red"
        }
    }

    private var healthSubtitleKey: LocalizedStringKey {
        switch healthStatus {
        case .green: "settings.diagnostics.health.subtitle.green"
        case .yellow: "settings.diagnostics.health.subtitle.yellow"
        case .red: "settings.diagnostics.health.subtitle.red"
        }
    }

    /// Round-12 slice 1: per-category pending breakdown shown as a disclosure
    /// inside the existing "Schedule health" view chain (rendered when the
    /// user expands the Advanced disclosure group).
    @ViewBuilder
    var pendingByCategorySection: some View {
        if let counts = pendingByCategory {
            Section {
                DisclosureGroup(isExpanded: $pendingByCategoryExpanded) {
                    row(
                        label: "settings.diagnostics.pendingByCat.routine",
                        value: String(counts.routine)
                    )
                    row(
                        label: "settings.diagnostics.pendingByCat.medFu",
                        value: String(counts.medicationFollowUp)
                    )
                    row(
                        label: "settings.diagnostics.pendingByCat.hydration",
                        value: String(counts.hydration)
                    )
                    row(
                        label: "settings.diagnostics.pendingByCat.milestones",
                        value: String(counts.milestones)
                    )
                    row(
                        label: "settings.diagnostics.pendingByCat.housekeeping",
                        value: String(counts.housekeeping)
                    )
                    row(
                        label: "settings.diagnostics.pendingByCat.other",
                        value: String(counts.other)
                    )
                } label: {
                    HStack {
                        Text("settings.diagnostics.section.pendingByCat", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(counts.total)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Round-12 slice 2: per-document byte size (expand to see).
    @ViewBuilder
    var tripDocsDetailSection: some View {
        if !tripDocumentDetails.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $tripDocsExpanded) {
                    ForEach(Array(tripDocumentDetails.enumerated()), id: \.offset) { _, doc in
                        HStack {
                            Text(verbatim: doc.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(verbatim: Self.formatBytes(doc.bytes))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    HStack {
                        Text("settings.diagnostics.section.tripDocsDetail", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(tripDocumentDetails.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Round-12 slice 19: launch history.
    @ViewBuilder
    var launchHistorySection: some View {
        if !launchHistory.isEmpty {
            Section {
                ForEach(launchHistory) { entry in
                    HStack {
                        Text(verbatim: entry.launchedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.caption.monospacedDigit())
                        Spacer()
                        if let prev = entry.previousDurationSeconds {
                            Text(verbatim: Self.formatUptime(prev))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: "—")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("settings.diagnostics.section.launchHistory", bundle: .main)
            }
        }
    }

    /// Round-12 slice 18: rolling history of "What's new" commits.
    @ViewBuilder
    var whatsNewHistorySection: some View {
        if !whatsNewHistory.isEmpty {
            Section {
                ForEach(whatsNewHistory) { entry in
                    HStack {
                        Text(verbatim: entry.commitSHA)
                            .font(.caption.monospacedDigit())
                        Spacer()
                        Text(verbatim: entry.seenAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("settings.diagnostics.section.whatsNewHistory", bundle: .main)
            }
        }
    }
}
