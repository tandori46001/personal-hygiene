import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("settings.notifications.status", bundle: .main)
                        Spacer()
                        Text(localizedStatus(viewModel.status))
                            .foregroundStyle(.secondary)
                    }
                    if viewModel.status == .notDetermined {
                        Button {
                            Task { await viewModel.requestPermission() }
                        } label: {
                            Text("settings.notifications.action.request", bundle: .main)
                        }
                    } else if viewModel.status == .denied {
                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            Text("settings.notifications.action.openSettings", bundle: .main)
                        }
                    }
                } header: {
                    Text("settings.section.notifications", bundle: .main)
                }

                Section {
                    Button {
                        Task { await viewModel.refreshNotifications() }
                    } label: {
                        Text("settings.notifications.action.refresh", bundle: .main)
                    }
                    .disabled(viewModel.status != .authorized && viewModel.status != .provisional)

                    if let last = viewModel.lastRefreshAt {
                        Text(
                            LocalizedStringResource(
                                "settings.notifications.lastRefresh \(last.formatted(date: .omitted, time: .shortened))"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("settings.section.scheduling", bundle: .main)
                }
            }
            .navigationTitle(Text("settings.title", bundle: .main))
            .task { await viewModel.reloadStatus() }
        }
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
