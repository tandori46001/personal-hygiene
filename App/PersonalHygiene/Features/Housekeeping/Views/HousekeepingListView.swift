import SwiftUI

struct HousekeepingListView: View {
    @Bindable var viewModel: HousekeepingListViewModel

    @State private var showingNewSheet = false
    @State private var newTitle = ""
    @State private var newRecurrence: HousekeepingRecurrence = .weekly
    @State private var newEscalationDays = 2

    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                    }
                }

                if viewModel.tasks.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("housekeeping.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "checklist")
                        }
                    } description: {
                        Text("housekeeping.empty.description", bundle: .main)
                    }
                } else {
                    ForEach(viewModel.tasks) { task in
                        HousekeepingRow(
                            task: task,
                            status: viewModel.status(for: task),
                            onComplete: { viewModel.markDone(task) }
                        )
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.markDone(task)
                            } label: {
                                Label {
                                    Text("housekeeping.action.complete", bundle: .main)
                                } icon: {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(task)
                            } label: {
                                Label {
                                    Text("common.delete", bundle: .main)
                                } icon: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("housekeeping.title", bundle: .main))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("housekeeping.action.add", bundle: .main))
                }
            }
            .onAppear { viewModel.reload() }
            .sheet(isPresented: $showingNewSheet) {
                newTaskSheet
            }
        }
    }

    @ViewBuilder
    private var newTaskSheet: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $newTitle,
                    prompt: Text("housekeeping.field.title.placeholder", bundle: .main)
                ) {
                    Text("housekeeping.field.title", bundle: .main)
                }
                Picker(selection: $newRecurrence) {
                    ForEach(HousekeepingRecurrence.allCases, id: \.self) { recurrence in
                        Text(LocalizedStringKey("housekeeping.recurrence.\(recurrence.rawValue)"))
                            .tag(recurrence)
                    }
                } label: {
                    Text("housekeeping.field.recurrence", bundle: .main)
                }
                Stepper(value: $newEscalationDays, in: 0...14) {
                    HStack {
                        Text("housekeeping.field.escalation", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(newEscalationDays) d")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("housekeeping.new.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingNewSheet = false
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.add(
                            title: newTitle,
                            recurrence: newRecurrence,
                            escalationDays: newEscalationDays
                        )
                        newTitle = ""
                        newRecurrence = .weekly
                        newEscalationDays = 2
                        showingNewSheet = false
                    } label: {
                        Text("common.create", bundle: .main)
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct HousekeepingRow: View {
    let task: HousekeepingTask
    let status: HousekeepingStatus
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                Text(LocalizedStringKey("housekeeping.recurrence.\(task.recurrence.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .pending:
            Text("housekeeping.status.pending", bundle: .main)
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .ok:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel(Text("housekeeping.status.ok", bundle: .main))
        case .dueToday:
            Text("housekeeping.status.dueToday", bundle: .main)
                .font(.caption.bold())
                .foregroundStyle(.orange)
        case .overdue:
            Text("housekeeping.status.overdue", bundle: .main)
                .font(.caption.bold())
                .foregroundStyle(.red)
        }
    }
}
