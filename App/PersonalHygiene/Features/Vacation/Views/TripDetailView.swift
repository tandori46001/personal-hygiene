import SwiftUI

struct TripDetailView: View {
    @Bindable var viewModel: TripDetailViewModel

    @State private var milestoneSheet: MilestoneSheetState?

    private enum MilestoneSheetState: Identifiable {
        case create
        case edit(TripMilestone)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let milestone): milestone.id.uuidString
            }
        }
    }

    var body: some View {
        Form {
            if let error = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                }
            }

            Section {
                TextField(
                    text: $viewModel.trip.name,
                    prompt: Text("trips.field.name.placeholder", bundle: .main)
                ) {
                    Text("trips.field.name", bundle: .main)
                }
                TextField(
                    text: $viewModel.trip.destinationName,
                    prompt: Text("trips.field.destination.placeholder", bundle: .main)
                ) {
                    Text("trips.field.destination", bundle: .main)
                }
                DatePicker(
                    selection: $viewModel.trip.startDate,
                    displayedComponents: .date
                ) {
                    Text("trips.field.startDate", bundle: .main)
                }
                DatePicker(
                    selection: $viewModel.trip.endDate,
                    in: viewModel.trip.startDate...,
                    displayedComponents: .date
                ) {
                    Text("trips.field.endDate", bundle: .main)
                }
            } header: {
                Text("trip.detail.section.summary", bundle: .main)
            } footer: {
                let days = viewModel.daysUntilDeparture()
                if days > 0 {
                    Text("trip.detail.countdown.\(days)", bundle: .main)
                }
            }

            Section {
                if viewModel.sortedMilestones.isEmpty {
                    Text("trip.detail.milestones.empty", bundle: .main)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.sortedMilestones) { milestone in
                        Button {
                            milestoneSheet = .edit(milestone)
                        } label: {
                            MilestoneRow(
                                milestone: milestone,
                                onToggle: { viewModel.toggleMilestoneCompletion(milestone) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteMilestones)
                }
                Button {
                    milestoneSheet = .create
                } label: {
                    Label {
                        Text("trip.milestone.action.add", bundle: .main)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            } header: {
                Text("trip.detail.section.milestones", bundle: .main)
            }

            Section {
                if viewModel.sortedDocuments.isEmpty {
                    Text("trip.detail.documents.empty", bundle: .main)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.sortedDocuments) { document in
                        DocumentRow(document: document)
                    }
                    .onDelete(perform: deleteDocuments)
                }
            } header: {
                Text("trip.detail.section.documents", bundle: .main)
            }
        }
        .navigationTitle(viewModel.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel.saveEdits() }
        .sheet(item: $milestoneSheet) { state in
            switch state {
            case .create:
                MilestoneEditorView(mode: .create) { title, days, _ in
                    viewModel.addMilestone(title: title, daysBefore: days)
                }
            case .edit(let milestone):
                MilestoneEditorView(mode: .edit(milestone)) { title, days, isDone in
                    viewModel.updateMilestone(milestone, title: title, daysBefore: days, isComplete: isDone)
                }
            }
        }
    }

    private func deleteMilestones(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteMilestone(viewModel.sortedMilestones[idx])
        }
    }

    private func deleteDocuments(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteDocument(viewModel.sortedDocuments[idx])
        }
    }
}

private struct MilestoneRow: View {
    let milestone: TripMilestone
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(milestone.isComplete ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                milestone.isComplete
                    ? Text("trip.milestone.action.unmarkDone", bundle: .main)
                    : Text("trip.milestone.action.markDone", bundle: .main)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.body)
                Text("trip.milestone.daysBefore.\(milestone.daysBefore)", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct DocumentRow: View {
    let document: TripDocument

    var body: some View {
        HStack {
            Image(systemName: documentIconName)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.body)
                Text(LocalizedStringKey("trip.document.kind.\(document.kind.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var documentIconName: String {
        switch document.kind {
        case .passport: "person.text.rectangle"
        case .visa: "doc.text.below.ecg"
        case .insurance: "cross.case"
        case .ticket: "ticket"
        case .reservation: "bed.double"
        case .other: "doc"
        }
    }
}
