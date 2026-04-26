import SwiftUI

struct BirthdaysView: View {
    @Bindable var viewModel: BirthdaysViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.status {
                case .notDetermined:
                    permissionPrompt
                case .denied, .restricted:
                    deniedState
                case .authorized, .limited:
                    listView
                }
            }
            .navigationTitle(Text("birthdays.title", bundle: .main))
            .task {
                viewModel.reloadStatus()
                await viewModel.reload()
            }
        }
    }

    private var permissionPrompt: some View {
        ContentUnavailableView {
            Label {
                Text("birthdays.permission.title", bundle: .main)
            } icon: {
                Image(systemName: "person.crop.circle.badge.questionmark")
            }
        } description: {
            Text("birthdays.permission.description", bundle: .main)
        } actions: {
            Button {
                Task { await viewModel.requestAccess() }
            } label: {
                Text("birthdays.permission.action", bundle: .main)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var deniedState: some View {
        ContentUnavailableView {
            Label {
                Text("birthdays.denied.title", bundle: .main)
            } icon: {
                Image(systemName: "lock")
            }
        } description: {
            Text("birthdays.denied.description", bundle: .main)
        } actions: {
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Text("settings.notifications.action.openSettings", bundle: .main)
            }
        }
    }

    @ViewBuilder
    private var listView: some View {
        if viewModel.upcoming.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("birthdays.empty.title", bundle: .main)
                } icon: {
                    Image(systemName: "gift")
                }
            } description: {
                Text("birthdays.empty.description", bundle: .main)
            }
        } else {
            List(viewModel.upcoming, id: \.contact.identifier) { entry in
                BirthdayRow(entry: entry)
            }
        }
    }
}

private struct BirthdayRow: View {
    let entry: UpcomingBirthdays.Upcoming

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.contact.displayName)
                    .font(.body)
                Text(entry.nextOccurrence, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(LocalizedStringResource("birthdays.daysUntil \(entry.daysUntil)"))
                .font(.caption.bold())
                .foregroundStyle(entry.daysUntil <= 7 ? .orange : .secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
