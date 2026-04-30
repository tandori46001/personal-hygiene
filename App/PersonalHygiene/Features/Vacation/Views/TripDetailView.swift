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

            // Round 35 IA redesign: phase-aligned ordering (basics → before
            // you go → during the trip → resources → after-the-fact). 18
            // sections collapsed to ~12 by combining 4 single-row navigation
            // sections (auto-itinerary, marine, currency, advisory) + the
            // wizard button into one "About your destination" section, and
            // by collapsing NextMilestone + Completion bar into one "My
            // progress" section. Carbon kg/lb unit picker moved to Settings
            // → Home & Travel (it was already @AppStorage-global; the UI
            // just looked per-trip).

            CoverPhotoSection(viewModel: viewModel, pickerItem: $coverPickerItem)
            summarySection
            progressSection
            milestonesSection(milestoneSheet: $milestoneSheet)
            PackingListSection(
                viewModel: viewModel,
                newItemTitle: $newPackingItemTitle,
                newItemCategory: $newPackingItemCategory
            )
            destinationInfoSection(showingWizard: $showingItineraryWizard)
            documentsSection(showingScanner: $showingScanner)
            TripEmergencyContactsSection(
                viewModel: viewModel,
                newLabel: $newEmergencyLabel,
                newPhone: $newEmergencyPhone
            )
            TripNotesSection(viewModel: viewModel)
            TripExpensesSection(
                viewModel: viewModel,
                newLabel: $newExpenseLabel,
                newAmount: $newExpenseAmount,
                newCurrency: $newExpenseCurrency
            )
            TripCurrencySnapshotSection(viewModel: viewModel)
            TripCarbonSection(viewModel: viewModel, homeLocation: HomeLocationStore().location)
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
