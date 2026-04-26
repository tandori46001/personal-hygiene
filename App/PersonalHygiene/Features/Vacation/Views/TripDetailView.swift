import PhotosUI
import SwiftUI

struct TripDetailView: View {
    @Bindable var viewModel: TripDetailViewModel

    @State private var milestoneSheet: MilestoneSheetState?
    @State private var showingScanner = false
    @State private var pendingDocumentBytes: PendingDocument?
    @State private var pendingExport: ExportPayload?
    @State private var coverPickerItem: PhotosPickerItem?
    @State private var newPackingItemTitle: String = ""

    private struct ExportPayload: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct PendingDocument: Identifiable {
        let id = UUID()
        let bytes: Data
    }

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

            CoverPhotoSection(viewModel: viewModel, pickerItem: $coverPickerItem)

            Section {
                TextField(
                    text: $viewModel.draftName,
                    prompt: Text("trips.field.name.placeholder", bundle: .main)
                ) {
                    Text("trips.field.name", bundle: .main)
                }
                TextField(
                    text: $viewModel.draftDestination,
                    prompt: Text("trips.field.destination.placeholder", bundle: .main)
                ) {
                    Text("trips.field.destination", bundle: .main)
                }
                DatePicker(
                    selection: $viewModel.draftStartDate,
                    displayedComponents: .date
                ) {
                    Text("trips.field.startDate", bundle: .main)
                }
                DatePicker(
                    selection: $viewModel.draftEndDate,
                    in: viewModel.draftStartDate...,
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

            if let generator = viewModel.itineraryGenerator {
                Section {
                    NavigationLink {
                        ItineraryView(
                            trip: viewModel.trip,
                            generator: generator,
                            store: viewModel.itineraryStore
                        )
                    } label: {
                        Label {
                            Text("trip.itinerary.title", bundle: .main)
                        } icon: {
                            Image(systemName: "wand.and.stars")
                        }
                    }
                }
            }

            MarineSection(viewModel: viewModel)

            if let currency = viewModel.currencyService {
                Section {
                    NavigationLink {
                        CurrencyView(service: currency)
                    } label: {
                        Label {
                            Text("trip.currency.title", bundle: .main)
                        } icon: {
                            Image(systemName: "dollarsign.arrow.circlepath")
                        }
                    }
                }
            }

            if let advisory = viewModel.advisoryLink {
                Section {
                    NavigationLink {
                        AdvisoryView(link: advisory)
                    } label: {
                        Label {
                            Text("trip.advisory.title", bundle: .main)
                        } icon: {
                            Image(systemName: "exclamationmark.shield")
                        }
                    }
                }
            }

            PackingListSection(viewModel: viewModel, newItemTitle: $newPackingItemTitle)

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
                        showingScanner = true
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
        .navigationTitle(viewModel.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    viewModel.revertDraft()
                } label: {
                    Text("common.cancel", bundle: .main)
                }
                .disabled(!viewModel.hasChanges)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.commitDraft()
                } label: {
                    Text("common.save", bundle: .main)
                }
                .disabled(
                    !viewModel.hasChanges
                        || viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || viewModel.draftDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(Text("trip.action.share", bundle: .main))
            }
        }
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
        #if canImport(VisionKit)
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScannerView { result in
                showingScanner = false
                switch result {
                case .success(let data):
                    pendingDocumentBytes = PendingDocument(bytes: data)
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                case .cancelled:
                    break
                }
            }
            .ignoresSafeArea()
        }
        #endif
        .sheet(item: $pendingDocumentBytes) { pending in
            DocumentMetadataSheet(bytes: pending.bytes) { name, kind in
                viewModel.addDocument(name: name, kind: kind, bytes: pending.bytes)
                pendingDocumentBytes = nil
            }
        }
        .sheet(item: $pendingExport) { payload in
            ShareSheet(items: [payload.url])
        }
    }

    private func exportPDF() {
        let bytes = TripPDFExporter.render(trip: viewModel.trip)
        let safeName = viewModel.trip.name
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = "\(safeName.isEmpty ? "Trip" : safeName).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try bytes.write(to: url, options: .atomic)
            pendingExport = ExportPayload(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
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
