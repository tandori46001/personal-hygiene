import SwiftUI
import UserNotifications

/// Diagnostics view that lists every pending `UNNotificationRequest` so the
/// developer can confirm scheduling on a real device without waiting hours.
/// Groups by source via `BlockNotificationIdentifier.parseAny`.
struct PendingNotificationsView: View {

    @State private var rows: [Row] = []
    @State private var loadError: String?
    @State private var isLoading = false

    struct Row: Identifiable {
        let id: String
        let identifier: String
        let source: BlockSnoozeSource?
        let title: String
        let body: String
        let triggerDescription: String
    }

    var body: some View {
        List {
            if let loadError {
                Section {
                    ErrorBanner(message: loadError, onDismiss: { self.loadError = nil })
                }
            }
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("settings.pendingNotifications.loading", bundle: .main)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if rows.isEmpty && !isLoading {
                Section {
                    ContentUnavailableView {
                        Label {
                            Text("settings.pendingNotifications.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "bell.slash")
                        }
                    } description: {
                        Text("settings.pendingNotifications.empty.description", bundle: .main)
                    }
                }
            } else {
                ForEach(BlockSnoozeSource.allCases, id: \.self) { source in
                    let group = rows.filter { $0.source == source }
                    if !group.isEmpty {
                        Section {
                            ForEach(group) { row in PendingRow(row: row) }
                        } header: {
                            Text(localizedKey: "settings.pendingNotifications.source.\(source.rawValue)")
                        }
                    }
                }
                let unknown = rows.filter { $0.source == nil }
                if !unknown.isEmpty {
                    Section {
                        ForEach(unknown) { row in PendingRow(row: row) }
                    } header: {
                        Text("settings.pendingNotifications.source.unknown", bundle: .main)
                    }
                }
            }
        }
        .navigationTitle(Text("settings.pendingNotifications.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        rows = requests.map { request -> Row in
            let parsed = BlockNotificationIdentifier.parseAny(request.identifier)
            return Row(
                id: request.identifier,
                identifier: request.identifier,
                source: parsed?.source,
                title: request.content.title,
                body: request.content.body,
                triggerDescription: Self.describe(trigger: request.trigger)
            )
        }
        .sorted { $0.identifier < $1.identifier }
    }

    private static func describe(trigger: UNNotificationTrigger?) -> String {
        switch trigger {
        case let cal as UNCalendarNotificationTrigger:
            if let next = cal.nextTriggerDate() {
                return next.formatted(date: .abbreviated, time: .shortened)
            }
            return "—"
        case let interval as UNTimeIntervalNotificationTrigger:
            return "+\(Int(interval.timeInterval))s"
        default:
            return "—"
        }
    }
}

private struct PendingRow: View {
    let row: PendingNotificationsView.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: row.title.isEmpty ? row.identifier : row.title)
                .font(.body)
            if !row.body.isEmpty {
                Text(verbatim: row.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Text(verbatim: row.triggerDescription)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: row.identifier.suffix(28).description)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
