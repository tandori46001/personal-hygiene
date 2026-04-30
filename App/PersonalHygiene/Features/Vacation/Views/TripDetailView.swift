import PhotosUI
import SwiftUI

struct TripDetailView: View {
    @Bindable var viewModel: TripDetailViewModel

    @State private var milestoneSheet: MilestoneSheetState?
    @State private var showingScanner = false
    @State private var pendingDocumentBytes: PendingDocument?
    @State var pendingExport: TripDetailExportPayload?
    @State private var coverPickerItem: PhotosPickerItem?
    @State private var newPackingItemTitle: String = ""
    @State private var newPackingItemCategory: PackingCategory = .other
    @State var showingArchiveConfirm = false
    @State private var newExpenseLabel: String = ""
    @State private var newExpenseAmount: String = ""
    @State private var newExpenseCurrency: String = "USD"
    @State private var newEmergencyLabel: String = ""
    @State private var newEmergencyPhone: String = ""
    @State var pendingMarkdownShare: TripDetailExportPayload?
    @State private var showingItineraryWizard = false

    private struct PendingDocument: Identifiable {
        let id = UUID()
        let bytes: Data
    }

    /// Round 32 (K01): dropped `private` so `TripDetailFormSections.swift`
    /// extension can use this in the `milestonesSection` parameter type.
    /// Still nested under `TripDetailView` so external code references it
    /// as `TripDetailView.MilestoneSheetState` — no namespace pollution.
    enum MilestoneSheetState: Identifiable {
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
            NextMilestoneSection(viewModel: viewModel)
            TripCompletionSection(viewModel: viewModel)
            TripCarbonSection(viewModel: viewModel, homeLocation: HomeLocationStore().location)

            summarySection
            milestonesSection(milestoneSheet: $milestoneSheet)

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

            // Round 27 WS-A: questionnaire-driven AI itinerary wizard.
            // Always available — does not require Apple Intelligence
            // (clipboard fallback works on every device).
            Section {
                Button {
                    showingItineraryWizard = true
                } label: {
                    Label {
                        Text("itinerary.wizard.entry", bundle: .main)
                    } icon: {
                        Image(systemName: "sparkles.rectangle.stack")
                    }
                }
            } footer: {
                Text("itinerary.wizard.entry.footer", bundle: .main)
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

            if !viewModel.advisoryLinks.isEmpty {
                Section {
                    NavigationLink {
                        AdvisoryView(
                            links: viewModel.advisoryLinks,
                            destination: viewModel.trip.destinationName
                        )
                    } label: {
                        Label {
                            Text("trip.advisory.title", bundle: .main)
                        } icon: {
                            Image(systemName: "exclamationmark.shield")
                        }
                    }
                }
            }

            PackingListSection(
                viewModel: viewModel,
                newItemTitle: $newPackingItemTitle,
                newItemCategory: $newPackingItemCategory
            )

            TripNotesSection(viewModel: viewModel)
            TripCurrencySnapshotSection(viewModel: viewModel)
            TripExpensesSection(
                viewModel: viewModel,
                newLabel: $newExpenseLabel,
                newAmount: $newExpenseAmount,
                newCurrency: $newExpenseCurrency
            )
            TripEmergencyContactsSection(
                viewModel: viewModel,
                newLabel: $newEmergencyLabel,
                newPhone: $newEmergencyPhone
            )

            documentsSection(showingScanner: $showingScanner)
        }
        .navigationTitle(viewModel.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show Cancel only when there's a pending draft. With no changes
            // we let the system back arrow handle navigation — the user was
            // getting stuck here when both buttons were disabled.
            if viewModel.hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.revertDraft()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.commitDraft()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(
                        viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || viewModel.draftDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            ToolbarItem(placement: .primaryAction) {
                tripActionMenu
            }
        }
        .confirmationDialog(
            Text("trip.archive.confirm.title", bundle: .main),
            isPresented: $showingArchiveConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                viewModel.archiveNow()
            } label: {
                Text("trip.archive.confirm.action", bundle: .main)
            }
            Button(role: .cancel) {} label: {
                Text("common.cancel", bundle: .main)
            }
        } message: {
            Text("trip.archive.confirm.message", bundle: .main)
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
        .sheet(item: $pendingMarkdownShare) { payload in
            ShareSheet(items: [payload.url])
        }
        // Round 27 WS-A A9: questionnaire-driven AI itinerary wizard.
        .sheet(isPresented: $showingItineraryWizard) {
            ItineraryWizardView(trip: viewModel.trip)
        }
    }

}
