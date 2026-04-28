import SwiftUI
import UserNotifications

/// Settings → Diagnostics screen. Surfaces things you'd want to know when
/// reporting a bug or verifying state on a real device: app version, commit,
/// notification authorization status, last refresh, pending count, deep link
/// into `PendingNotificationsView`, plus a few dev-only buttons that fast-
/// forward state for on-device QA.
/// Identifiable wrapper so the snapshot URL can drive a `sheet(item:)`.
struct ExportURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct DiagnosticsView: View {

    let viewModel: SettingsViewModel
    let actions: DiagnosticsActions

    @State private var pendingCount: Int?
    @State private var deliveredCount: Int?
    @State private var criticalAlertsEnabled: Bool?
    @State private var pendingError: String?
    @State private var lastDevAction: String?
    @State private var showingResetConfirm = false
    // Round-10 sections (rendered from `DiagnosticsViewSections.swift` extension)
    // need access to these — leave package-internal, not `private`.
    @State var refreshTrace: [RefreshTraceLog.Entry] = []
    @State var scheduleDiff: (pending: Int, expected: Int)?
    @State var widgetReloadCount: Int = 0
    @State var observerSnapshot: (available: Bool, identifiers: [String]) = (false, [])
    @State var tripDocumentCount: Int = 0
    @State var tripDocumentBytes: Int?
    @State var tripDocumentDetails: [(name: String, bytes: Int)] = []
    @State var processUptime: TimeInterval = 0
    @State var snapshotExportURL: URL?
    @State var exportingSnapshot = false
    @State var advancedExpanded = false
    @State var pendingByCategory: PendingNotificationsByCategory?
    @State var launchHistory: [ProcessLaunchHistoryStore.Entry] = []
    @State var whatsNewHistory: [WhatsNewHistoryStore.Entry] = []
    @State var refreshTraceFilter: RefreshTraceKind?
    @State var pendingByCategoryExpanded = false
    @State var tripDocsExpanded = false
    @State var snapshotHistory: [DiagnosticsSnapshot] = []
    @State var authTimeline: [NotificationAuthTimelineLog.Entry] = []
    @State var networkCounts: [NetworkActivityCounter.Source: Int] = [:]
    @State var pendingDetails: [DiagnosticsSnapshot.PendingNotificationSummary] = []
    @State var snapshotHistoryExpanded = false
    @State var pendingDetailsExpanded = false
    @State var pendingByGroupExpanded = false

    var body: some View {
        List {
            Section {
                row(label: "settings.diagnostics.version", value: BuildInfo.marketingVersion)
                row(label: "settings.diagnostics.build", value: BuildInfo.bundleVersion)
                row(label: "settings.diagnostics.commit", value: BuildInfo.commitSHA)
            } header: {
                Text("settings.diagnostics.section.app", bundle: .main)
            }

            Section {
                row(
                    label: "settings.diagnostics.notif.status",
                    value: localizedStatus(viewModel.status)
                )
                if let last = viewModel.lastRefreshAt {
                    row(
                        label: "settings.diagnostics.notif.lastRefresh",
                        value: last.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                row(
                    label: "settings.diagnostics.notif.pendingCount",
                    value: pendingCount.map(String.init) ?? "—"
                )
                NavigationLink {
                    PendingNotificationsView()
                } label: {
                    Label {
                        Text("settings.diagnostics.openPending", bundle: .main)
                    } icon: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
                row(
                    label: "settings.diagnostics.notif.deliveredCount",
                    value: deliveredCount.map(String.init) ?? "—"
                )
                NavigationLink {
                    RecentlyDeliveredNotificationsView()
                } label: {
                    Label {
                        Text("settings.diagnostics.openDelivered", bundle: .main)
                    } icon: {
                        Image(systemName: "checkmark.bubble")
                    }
                }
                row(
                    label: "settings.diagnostics.notif.criticalAlerts",
                    value: criticalAlertsEnabled.map { $0 ? "✓" : "—" } ?? "—"
                )
            } header: {
                Text("settings.diagnostics.section.notifications", bundle: .main)
            }

            healthBadgeSection
            uptimeSection
            advancedDisclosureSection
            // Round-24 wrapper for the round-23 helpers (cache counters,
            // housekeeping log dump, backup size projection, archived
            // templates, mood streak record).
            round24Sections

            devToolsSection

            if let lastDevAction {
                Section {
                    Text(verbatim: lastDevAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(Text("settings.diagnostics.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshCounts() }
        .refreshable { await refreshCounts() }
        .sheet(item: Binding(
            get: { snapshotExportURL.map { ExportURL(url: $0) } },
            set: { _ in snapshotExportURL = nil }
        )) { wrapper in
            ShareSheet(items: [wrapper.url])
        }
        .confirmationDialog(
            Text("settings.diagnostics.devTools.reset.confirm.title", bundle: .main),
            isPresented: $showingResetConfirm,
            titleVisibility: .visible,
            actions: {
                Button(role: .destructive) {
                    actions.resetDevStores()
                    lastDevAction = String(localized: "settings.diagnostics.devTools.reset.done")
                } label: {
                    Text("settings.diagnostics.devTools.reset.action", bundle: .main)
                }
                Button(role: .cancel) {} label: {
                    Text("common.cancel", bundle: .main)
                }
            }
        )
    }

    @ViewBuilder
    private var devToolsSection: some View {
        Section {
            Button {
                Task {
                    await actions.scheduleTestNotification()
                    lastDevAction = String(localized: "settings.diagnostics.devTools.testNotif.done")
                    await refreshCounts()
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.testNotif", bundle: .main)
                } icon: {
                    Image(systemName: "bell.badge")
                }
            }

            Button {
                Task {
                    await actions.scheduleMedicationTest()
                    lastDevAction = String(
                        localized: "settings.diagnostics.devTools.medicationTest.done"
                    )
                    await refreshCounts()
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.medicationTest", bundle: .main)
                } icon: {
                    Image(systemName: "pills.circle")
                }
            }

            Button {
                Task {
                    if let title = await actions.replayLastDelivered() {
                        lastDevAction = String(
                            localized: "settings.diagnostics.devTools.replay.done \(title)"
                        )
                    } else {
                        lastDevAction = String(
                            localized: "settings.diagnostics.devTools.replay.empty"
                        )
                    }
                    await refreshCounts()
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.replay", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.clockwise.circle")
                }
            }

            Button {
                Task {
                    await actions.requestAuthorization()
                    await viewModel.reloadStatus()
                    lastDevAction = String(
                        localized: "settings.diagnostics.devTools.requestAuth.done"
                    )
                    await refreshCounts()
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.requestAuth", bundle: .main)
                } icon: {
                    Image(systemName: "lock.shield")
                }
            }

            Button(role: .destructive) {
                Task {
                    await actions.clearAllPending()
                    lastDevAction = String(localized: "settings.diagnostics.devTools.clearPending.done")
                    await refreshCounts()
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.clearPending", bundle: .main)
                } icon: {
                    Image(systemName: "bell.slash")
                }
            }

            Button {
                if let title = actions.injectSnoozeBadge() {
                    lastDevAction = String(
                        localized: "settings.diagnostics.devTools.injectBadge.done \(title)"
                    )
                } else {
                    lastDevAction = String(
                        localized: "settings.diagnostics.devTools.injectBadge.empty"
                    )
                }
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.injectBadge", bundle: .main)
                } icon: {
                    Image(systemName: "alarm.waves.left.and.right")
                }
            }

            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label {
                    Text("settings.diagnostics.devTools.reset", bundle: .main)
                } icon: {
                    Image(systemName: "trash")
                }
            }
        } header: {
            Text("settings.diagnostics.section.devTools", bundle: .main)
        } footer: {
            Text("settings.diagnostics.section.devTools.footer", bundle: .main)
        }
    }

    func row(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label, bundle: .main)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }

    private func row(label: LocalizedStringKey, value: LocalizedStringKey) -> some View {
        HStack {
            Text(label, bundle: .main)
            Spacer()
            Text(value, bundle: .main)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func refreshCounts() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        pendingCount = requests.count
        let delivered = await center.deliveredNotifications()
        deliveredCount = delivered.count
        let settings = await center.notificationSettings()
        criticalAlertsEnabled = (settings.criticalAlertSetting == .enabled)
        refreshTrace = actions.refreshTrace()
        widgetReloadCount = actions.widgetReloadCount()
        observerSnapshot = actions.medicationObserverSnapshot()
        tripDocumentCount = actions.tripDocumentCount()
        tripDocumentBytes = actions.tripDocumentByteFootprint()
        tripDocumentDetails = actions.tripDocumentDetails()
        processUptime = actions.processUptimeSeconds()
        scheduleDiff = try? await actions.scheduleDiff()
        pendingByCategory = await actions.pendingByCategory()
        launchHistory = actions.launchHistory()
        whatsNewHistory = actions.whatsNewHistory()
        snapshotHistory = actions.snapshotHistory()
        authTimeline = actions.authTimeline()
        networkCounts = actions.networkCounts()
        pendingDetails = await actions.pendingDetails()
        // Round-13 slice 19: also record any auth-status change observed during refresh.
        NotificationAuthTimelineLog.record(statusRawValue: viewModel.status.rawValue)
    }

    private func localizedStatus(_ status: NotificationAuthorizationStatus) -> LocalizedStringKey {
        switch status {
        case .authorized: return "settings.notifications.status.authorized"
        case .provisional: return "settings.notifications.status.provisional"
        case .denied: return "settings.notifications.status.denied"
        case .ephemeral: return "settings.notifications.status.ephemeral"
        case .notDetermined: return "settings.notifications.status.notDetermined"
        }
    }
}
