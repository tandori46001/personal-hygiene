import SwiftUI
import UserNotifications

/// Settings → Diagnostics screen. Surfaces things you'd want to know when
/// reporting a bug or verifying state on a real device: app version, commit,
/// notification authorization status, last refresh, pending count, deep link
/// into `PendingNotificationsView`.
struct DiagnosticsView: View {

    let viewModel: SettingsViewModel

    @State private var pendingCount: Int?
    @State private var pendingError: String?

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
            } header: {
                Text("settings.diagnostics.section.notifications", bundle: .main)
            }
        }
        .navigationTitle(Text("settings.diagnostics.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshPendingCount() }
        .refreshable { await refreshPendingCount() }
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

    private func refreshPendingCount() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        pendingCount = requests.count
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
