import SwiftUI

struct BirthdaysView: View {
    @Bindable var viewModel: BirthdaysViewModel

    @State private var leadEditing: BirthdayContact?
    @State private var relationshipFilter: BirthdayRelationship?
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
            List {
                Section {
                    Button {
                        // Round-12 slice 35: pull a fresh copy from Contacts
                        // so newly-added contacts surface without forcing
                        // the user to wait for a scenePhase change.
                        Task { await viewModel.reload() }
                    } label: {
                        Label {
                            Text("birthdays.action.resync", bundle: .main)
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    // Round-15 slice 33: relationship filter chips.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Button {
                                relationshipFilter = nil
                            } label: {
                                Text("birthdays.filter.all", bundle: .main)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .tint(relationshipFilter == nil ? .accentColor : .secondary)
                            ForEach(BirthdayRelationship.allCases, id: \.self) { rel in
                                Button {
                                    relationshipFilter = rel
                                } label: {
                                    Label {
                                        Text(localizedKey: "birthdays.relationship.\(rel.rawValue)")
                                            .font(.caption.bold())
                                    } icon: {
                                        Image(systemName: rel.systemImage)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .tint(relationshipFilter == rel ? .accentColor : .secondary)
                            }
                        }
                    }
                }
                Section {
                    let filteredUpcoming = viewModel.upcoming.filter { entry in
                        guard let rel = relationshipFilter else { return true }
                        return BirthdayRelationshipStore.relationship(
                            for: entry.contact.identifier
                        ) == rel
                    }
                    ForEach(filteredUpcoming, id: \.contact.identifier) { entry in
                        BirthdayRow(
                            entry: entry,
                            leadDays: viewModel.leadDays(for: entry.contact),
                            hasOverride: viewModel.hasOverride(entry.contact)
                        )
                        .contextMenu {
                            // Round-18 slice 23: copy stored gift idea to clipboard.
                            if let idea = BirthdayIdeaStore.idea(for: entry.contact.identifier),
                               !idea.isEmpty {
                                Button {
                                    UIPasteboard.general.string = idea
                                } label: {
                                    Label {
                                        Text("birthdays.action.copyIdeas", bundle: .main)
                                    } icon: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                }
                            }
                        }
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
    }
}

private struct BirthdayRow: View {
    let entry: UpcomingBirthdays.Upcoming
    let leadDays: Int
    let hasOverride: Bool

    private var leadNotificationDate: Date? {
        Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: -leadDays,
            to: entry.nextOccurrence
        )
    }

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
                // Round-12 slice 36: per-contact lead notification preview.
                if let leadDate = leadNotificationDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text(
                            "birthdays.lead.preview \(leadDate.formatted(date: .abbreviated, time: .omitted))",
                            bundle: .main
                        )
                        .font(.caption2)
                        .foregroundStyle(.tint)
                    }
                    .accessibilityLabel(
                        Text(
                            "a11y.birthdays.leadPreview \(leadDate.formatted(date: .abbreviated, time: .omitted))",
                            bundle: .main
                        )
                    )
                }
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
                        .accessibilityElement(children: .combine)
                    }
                    .accessibilityLabel(Text("a11y.birthdays.leadStepper", bundle: .main))
                    .accessibilityValue(Text("birthdays.lead.\(draft)", bundle: .main))
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
