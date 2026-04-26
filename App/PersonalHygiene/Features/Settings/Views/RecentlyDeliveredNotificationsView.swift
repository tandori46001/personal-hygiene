import SwiftUI
import UserNotifications

/// Diagnostics view that lists `UNUserNotificationCenter.deliveredNotifications`
/// — what actually fired in the last 24h. Companion to `PendingNotificationsView`
/// for verifying the snooze/mark-done flows on a real device. Groups by
/// parsed source via `DeliveredNotificationsGrouper`.
struct RecentlyDeliveredNotificationsView: View {

    @State private var groups: [DeliveredNotificationsGrouper.Group] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("settings.recentlyDelivered.loading", bundle: .main)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if groups.isEmpty && !isLoading {
                Section {
                    ContentUnavailableView {
                        Label {
                            Text("settings.recentlyDelivered.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "bell.slash")
                        }
                    } description: {
                        Text("settings.recentlyDelivered.empty.description", bundle: .main)
                    }
                }
            } else {
                ForEach(groups, id: \.headerKey) { group in
                    Section {
                        ForEach(group.items, id: \.identifier) { item in
                            DeliveredRow(item: item)
                        }
                    } header: {
                        Text(LocalizedStringKey(group.headerKey))
                    }
                }
            }
        }
        .navigationTitle(Text("settings.recentlyDelivered.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        isLoading = true
        defer { isLoading = false }
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        let items = delivered.map { notification in
            DeliveredNotificationsGrouper.Item(
                identifier: notification.request.identifier,
                title: notification.request.content.title,
                body: notification.request.content.body,
                deliveredAt: notification.date
            )
        }
        groups = DeliveredNotificationsGrouper.group(items)
    }
}

private extension DeliveredNotificationsGrouper.Group {
    var headerKey: String {
        if let source { return "settings.pendingNotifications.source.\(source.rawValue)" }
        return "settings.pendingNotifications.source.unknown"
    }
}

private struct DeliveredRow: View {
    let item: DeliveredNotificationsGrouper.Item

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: item.title.isEmpty ? item.identifier : item.title)
                .font(.body)
            if !item.body.isEmpty {
                Text(verbatim: item.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Text(verbatim: item.deliveredAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: item.identifier.suffix(28).description)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
