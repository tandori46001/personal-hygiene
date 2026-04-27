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
                let filtered = refreshTrace.filter {
                    refreshTraceFilter == nil || $0.kind == refreshTraceFilter
                }
                Picker(selection: $refreshTraceFilter) {
                    Text("settings.diagnostics.refreshTrace.filter.all", bundle: .main)
                        .tag(RefreshTraceKind?.none)
                    Text("settings.diagnostics.refreshTrace.filter.refresh", bundle: .main)
                        .tag(RefreshTraceKind?.some(.refresh))
                    Text("settings.diagnostics.refreshTrace.filter.reschedule", bundle: .main)
                        .tag(RefreshTraceKind?.some(.reschedule))
                } label: {
                    Text("settings.diagnostics.refreshTrace.filter", bundle: .main)
                }
                .pickerStyle(.segmented)
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, entry in
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
            row(
                label: "settings.diagnostics.observ.tripDocBytes",
                value: tripDocumentBytes.map { Self.formatBytes($0) } ?? "—"
            )
        } header: {
            Text("settings.diagnostics.section.observability", bundle: .main)
        }
    }

    @ViewBuilder
    var uptimeSection: some View {
        Section {
            row(
                label: "settings.diagnostics.uptime.launchedAt",
                value: ProcessLaunchTimer.launchedAt.formatted(date: .abbreviated, time: .standard)
            )
            row(
                label: "settings.diagnostics.uptime.elapsed",
                value: Self.formatUptime(processUptime)
            )
        } header: {
            Text("settings.diagnostics.section.uptime", bundle: .main)
        }
    }

    @ViewBuilder
    var advancedDisclosureSection: some View {
        Section {
            DisclosureGroup(isExpanded: $advancedExpanded) {
                scheduleHealthSection
                pendingByCategorySection
                refreshTraceSection
                observabilitySection
                tripDocsDetailSection
                launchHistorySection
                whatsNewHistorySection
                snapshotHistorySection
                authTimelineSection
                networkActivitySection
                pendingDetailsSection
                Section {
                    Button {
                        Task {
                            exportingSnapshot = true
                            snapshotExportURL = try? await actions.exportSnapshot()
                            exportingSnapshot = false
                        }
                    } label: {
                        if exportingSnapshot {
                            HStack {
                                ProgressView()
                                Text("settings.diagnostics.snapshot.exporting", bundle: .main)
                            }
                        } else {
                            Label {
                                Text("settings.diagnostics.snapshot.export", bundle: .main)
                            } icon: {
                                Image(systemName: "square.and.arrow.up.on.square")
                            }
                        }
                    }
                    .disabled(exportingSnapshot)
                }
            } label: {
                Label {
                    Text("settings.diagnostics.section.advanced", bundle: .main)
                } icon: {
                    Image(systemName: "wrench.and.screwdriver")
                }
            }
        }
    }

    static func formatBytes(_ count: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(count))
    }

    static func formatUptime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: max(0, interval)) ?? "0s"
    }
}
