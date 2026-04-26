import SwiftUI

struct TripDetailView: View {
    @Bindable var viewModel: TripDetailViewModel

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
                        MilestoneRow(milestone: milestone)
                    }
                    .onDelete(perform: deleteMilestones)
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

    var body: some View {
        HStack {
            Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(milestone.isComplete ? Color.green : Color.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.body)
                Text("trip.milestone.daysBefore.\(milestone.daysBefore)", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
