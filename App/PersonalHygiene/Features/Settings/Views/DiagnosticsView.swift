import SwiftUI
import UserNotifications

/// Settings → Diagnostics screen. Surfaces things you'd want to know when
/// reporting a bug or verifying state on a real device: app version, commit,
/// notification authorization status, last refresh, pending count, deep link
/// into `PendingNotificationsView`, plus a few dev-only buttons that fast-
/// forward state for on-device QA.
struct DiagnosticsView: View {

    let viewModel: SettingsViewModel
    let actions: DiagnosticsActions

    @State private var pendingCount: Int?
    @State private var deliveredCount: Int?
    @State private var pendingError: String?
    @State private var lastDevAction: String?
    @State private var showingResetConfirm = false

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
            } header: {
                Text("settings.diagnostics.section.notifications", bundle: .main)
            }

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

    private func row(label: LocalizedStringKey, value: String) -> some View {
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
