import SwiftUI

struct BirthdaysView: View {
    @Bindable var viewModel: BirthdaysViewModel

    @State private var leadEditing: BirthdayContact?
    @Environment(\.scenePhase) private var scenePhase

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
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    viewModel.reloadStatus()
                    await viewModel.reload()
                }
            }
            .sheet(item: $leadEditing) { contact in
                BirthdayLeadEditorSheet(contact: contact, viewModel: viewModel)
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
                BirthdayRow(
                    entry: entry,
                    leadDays: viewModel.leadDays(for: entry.contact),
                    hasOverride: viewModel.hasOverride(entry.contact)
                )
                .swipeActions(edge: .trailing) {
                    Button {
                        leadEditing = entry.contact
                    } label: {
                        Label {
                            Text("birthdays.action.editLead", bundle: .main)
                        } icon: {
                            Image(systemName: "bell")
                        }
                    }
                    .tint(.blue)
                }
            }
        }
    }
}

private struct BirthdayRow: View {
    let entry: UpcomingBirthdays.Upcoming
    let leadDays: Int
    let hasOverride: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.contact.displayName)
                    .font(.body)
                HStack(spacing: 6) {
                    Text(entry.nextOccurrence, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    Text(verbatim: "•")
                    Text("birthdays.lead.\(leadDays)", bundle: .main)
                        .foregroundStyle(hasOverride ? .blue : .secondary)
                }
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

private struct BirthdayLeadEditorSheet: View {
    let contact: BirthdayContact
    @Bindable var viewModel: BirthdaysViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Int

    init(contact: BirthdayContact, viewModel: BirthdaysViewModel) {
        self.contact = contact
        self.viewModel = viewModel
        self._draft = State(initialValue: viewModel.leadDays(for: contact))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $draft, in: 0...60) {
                        HStack {
                            Text("birthdays.lead.field", bundle: .main)
                            Spacer()
                            Text("birthdays.lead.\(draft)", bundle: .main)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("birthdays.lead.footer.\(viewModel.defaultLeadDays)", bundle: .main)
                }
                if viewModel.hasOverride(contact) {
                    Section {
                        Button(role: .destructive) {
                            viewModel.clearLeadDays(for: contact)
                            dismiss()
                        } label: {
                            Text("birthdays.lead.action.useDefault", bundle: .main)
                        }
                    }
                }
            }
            .navigationTitle(Text(contact.displayName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.setLeadDays(draft, for: contact)
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                }
            }
        }
    }
}
