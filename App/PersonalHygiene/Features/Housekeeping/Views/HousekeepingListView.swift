import SwiftUI

struct HousekeepingListView: View {
    @Bindable var viewModel: HousekeepingListViewModel

    @State private var showingNewSheet = false
    @State private var newTitle = ""
    @State private var newRecurrence: HousekeepingRecurrence = .weekly
    @State private var newEscalationDays = 2
    @State private var newRoom = ""
    @State private var addingCustomRoom = false
    @State private var newRoomIconID: String = ""

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
                    if !viewModel.availableRooms.isEmpty || viewModel.hasUnsortedTasks {
                        Section {
                            Picker(selection: $viewModel.roomFilter) {
                                Text("housekeeping.filter.all", bundle: .main)
                                    .tag(HousekeepingListViewModel.RoomFilter.all)
                                ForEach(viewModel.availableRooms, id: \.self) { room in
                                    Text(verbatim: room)
                                        .tag(HousekeepingListViewModel.RoomFilter.named(room))
                                }
                                if viewModel.hasUnsortedTasks {
                                    Text("housekeeping.filter.unsorted", bundle: .main)
                                        .tag(HousekeepingListViewModel.RoomFilter.unsorted)
                                }
                            } label: {
                                Text("housekeeping.filter.label", bundle: .main)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    ForEach(viewModel.filteredTasks) { task in
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
    private var roomFieldSection: some View {
        if viewModel.availableRooms.isEmpty || addingCustomRoom {
            TextField(
                text: $newRoom,
                prompt: Text("housekeeping.field.room.placeholder", bundle: .main)
            ) {
                Text("housekeeping.field.room", bundle: .main)
            }
        } else {
            Picker(selection: $newRoom) {
                Text("housekeeping.field.room.none", bundle: .main).tag("")
                ForEach(viewModel.availableRooms, id: \.self) { room in
                    Text(verbatim: room).tag(room)
                }
            } label: {
                Text("housekeeping.field.room", bundle: .main)
            }
            Button {
                addingCustomRoom = true
                newRoom = ""
            } label: {
                Label {
                    Text("housekeeping.field.room.addNew", bundle: .main)
                } icon: {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }

    @ViewBuilder
    private var roomIconPickerSection: some View {
        let trimmed = newRoom.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            Picker(selection: $newRoomIconID) {
                Text("housekeeping.icon.none", bundle: .main).tag("")
                ForEach(HousekeepingRoomIcons.palette) { choice in
                    Label {
                        Text(LocalizedStringKey(choice.displayKey), bundle: .main)
                    } icon: {
                        Image(systemName: choice.id)
                    }
                    .tag(choice.id)
                }
            } label: {
                Text("housekeeping.field.roomIcon", bundle: .main)
            }
            .onAppear {
                if newRoomIconID.isEmpty {
                    newRoomIconID = HousekeepingRoomIconStore.iconID(forRoom: trimmed) ?? ""
                }
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
                roomFieldSection
                roomIconPickerSection
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
                        let trimmedRoom = newRoom.trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedRoom = trimmedRoom.isEmpty ? nil : trimmedRoom
                        viewModel.add(
                            title: newTitle,
                            recurrence: newRecurrence,
                            escalationDays: newEscalationDays,
                            room: resolvedRoom
                        )
                        if let resolvedRoom, !newRoomIconID.isEmpty {
                            HousekeepingRoomIconStore.setIconID(newRoomIconID, forRoom: resolvedRoom)
                        }
                        newTitle = ""
                        newRecurrence = .weekly
                        newEscalationDays = 2
                        newRoom = ""
                        newRoomIconID = ""
                        addingCustomRoom = false
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
                HStack(spacing: 6) {
                    Text(LocalizedStringKey("housekeeping.recurrence.\(task.recurrence.rawValue)"))
                    if let room = task.room {
                        Text(verbatim: "•")
                        if let iconID = HousekeepingRoomIconStore.iconID(forRoom: room) {
                            Image(systemName: iconID)
                                .accessibilityHidden(true)
                        }
                        Text(verbatim: room)
                    }
                }
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
