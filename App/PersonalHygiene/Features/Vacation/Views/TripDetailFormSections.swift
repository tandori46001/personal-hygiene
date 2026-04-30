import PhotosUI
import SwiftUI

/// Round 32 (K01): inline `Section { ... }` blocks from `TripDetailView.body`
/// extracted into `@ViewBuilder` properties so the parent view's body fits
/// under SwiftLint's `type_body_length` 300-line threshold without the
/// `// swiftlint:disable` paragraph that round 28 added. No behavior change —
/// purely structural decomposition. The sections still read the parent's
/// `@State` properties because extensions on the same type can access them.
extension TripDetailView {

    @ViewBuilder
    var summarySection: some View {
        Section {
            TextField(
                text: $viewModel.draftName,
                prompt: Text("trips.field.name.placeholder", bundle: .main)
            ) {
                Text("trips.field.name", bundle: .main)
            }
            LocationAutocompleteField(
                name: $viewModel.draftDestination,
                latitude: $viewModel.draftDestinationLatitude,
                longitude: $viewModel.draftDestinationLongitude
            )
            if viewModel.draftDestinationLatitude != nil {
                DestinationMapPreview(
                    name: viewModel.draftDestination,
                    latitude: viewModel.draftDestinationLatitude,
                    longitude: viewModel.draftDestinationLongitude
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            DismissingDatePicker(selection: $viewModel.draftStartDate) {
                Text("trips.field.startDate", bundle: .main)
            }
            DismissingDatePicker(
                selection: $viewModel.draftEndDate,
                minimumDate: viewModel.draftStartDate
            ) {
                Text("trips.field.endDate", bundle: .main)
            }
        } header: {
            // Round 27 follow-up: explicit pencil icon in the section header
            // so the user understands the fields are tappable + editable.
            HStack(spacing: 6) {
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.tint)
                Text("trip.detail.section.summary", bundle: .main)
            }
        } footer: {
            let days = viewModel.daysUntilDeparture()
            if days > 0 {
                Text("trip.detail.countdown.\(days)", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func milestonesSection(milestoneSheet: Binding<MilestoneSheetState?>) -> some View {
        Section {
            if viewModel.sortedMilestones.isEmpty {
                Text("trip.detail.milestones.empty", bundle: .main)
                    .foregroundStyle(.secondary)
                Button {
                    viewModel.addStandardMilestoneBundle()
                } label: {
                    Label {
                        Text("trip.milestone.action.addBundle", bundle: .main)
                    } icon: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            } else {
                ForEach(viewModel.sortedMilestones) { milestone in
                    Button {
                        milestoneSheet.wrappedValue = .edit(milestone)
                    } label: {
                        MilestoneRow(
                            milestone: milestone,
                            hasFired: hasFired(milestone),
                            onToggle: { viewModel.toggleMilestoneCompletion(milestone) }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteMilestones)
            }
            Button {
                milestoneSheet.wrappedValue = .create
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
    }

    @ViewBuilder
    func documentsSection(showingScanner: Binding<Bool>) -> some View {
        Section {
            if viewModel.sortedDocuments.isEmpty {
                Text("trip.detail.documents.empty", bundle: .main)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.sortedDocuments) { document in
                    if let store = viewModel.documentStore {
                        NavigationLink {
                            DocumentPreviewView(document: document, store: store)
                        } label: {
                            DocumentRow(document: document)
                        }
                    } else {
                        DocumentRow(document: document)
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            if viewModel.documentStore != nil {
                Button {
                    showingScanner.wrappedValue = true
                } label: {
                    Label {
                        Text("trip.document.action.scan", bundle: .main)
                    } icon: {
                        Image(systemName: "doc.viewfinder")
                    }
                }
            }
        } header: {
            Text("trip.detail.section.documents", bundle: .main)
        }
    }
}
