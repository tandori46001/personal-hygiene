import SwiftUI

struct TripsListView: View {
    @Bindable var viewModel: TripsListViewModel

    @State private var showingNewSheet = false
    @State private var newName = ""
    @State private var newDestination = ""
    @State private var newStart = Date()
    @State private var newEnd = Date().addingTimeInterval(7 * 24 * 60 * 60)

    @State private var pendingDuplicateSource: Trip?
    @State private var duplicateNameDraft: String = ""

    var body: some View {
        // L004: no inner `NavigationStack` here. This view lives inside the
        // iOS 18 TabView "More" overflow, which already wraps content in its
        // own NavigationStack. A second stack would render two stacked back
        // chevrons when pushing into TripDetailView.
        List {
            if let error = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                }
            }

            if viewModel.trips.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("trips.empty.title", bundle: .main)
                    } icon: {
                        Image(systemName: "airplane")
                    }
                } description: {
                    Text("trips.empty.description", bundle: .main)
                }
            } else {
                let upcoming = viewModel.upcomingTrips()
                let past = viewModel.pastTrips()

                if !upcoming.isEmpty {
                    let nearestID = viewModel.daysUntilNearest()?.0.id
                    Section {
                        ForEach(upcoming) { trip in
                            tripLink(for: trip, nearestID: nearestID)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        pendingDuplicateSource = trip
                                        duplicateNameDraft = "Copy of \(trip.name)"
                                    } label: {
                                        Label {
                                            Text("trips.action.duplicate", bundle: .main)
                                        } icon: {
                                            Image(systemName: "plus.square.on.square")
                                        }
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onDelete { offsets in delete(upcoming, at: offsets) }
                    } header: {
                        Text("trips.section.upcoming", bundle: .main)
                    }
                }

                if !past.isEmpty {
                    Section {
                        ForEach(past) { trip in
                            tripLink(for: trip, nearestID: nil)
                                .foregroundStyle(.secondary)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        pendingDuplicateSource = trip
                                        duplicateNameDraft = "Copy of \(trip.name)"
                                    } label: {
                                        Label {
                                            Text("trips.action.duplicate", bundle: .main)
                                        } icon: {
                                            Image(systemName: "plus.square.on.square")
                                        }
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onDelete { offsets in delete(past, at: offsets) }
                    } header: {
                        Text("trips.section.past", bundle: .main)
                    }
                }
            }
        }
        .navigationTitle(Text("trips.title", bundle: .main))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("trips.action.add", bundle: .main))
            }
        }
        .modifier(TripsSearchModifier(viewModel: viewModel))
        .onAppear { viewModel.reload() }
        .sheet(isPresented: $showingNewSheet) {
            newTripSheet
        }
        .alert(
            Text("trips.duplicate.alert.title", bundle: .main),
            isPresented: Binding(
                get: { pendingDuplicateSource != nil },
                set: { if !$0 { pendingDuplicateSource = nil } }
            ),
            presenting: pendingDuplicateSource
        ) { _ in
            TextField(
                LocalizedStringKey("trips.duplicate.alert.namePlaceholder"),
                text: $duplicateNameDraft
            )
            Button {
                if let source = pendingDuplicateSource {
                    let trimmed = duplicateNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = trimmed.isEmpty ? "Copy of \(source.name)" : trimmed
                    viewModel.duplicate(source, name: finalName)
                }
                pendingDuplicateSource = nil
            } label: {
                Text("trips.duplicate.alert.confirm", bundle: .main)
            }
            Button(role: .cancel) {
                pendingDuplicateSource = nil
            } label: {
                Text("common.cancel", bundle: .main)
            }
        } message: { source in
            Text("trips.duplicate.alert.message \(source.name)", bundle: .main)
        }
    }

    @ViewBuilder
    private var newTripSheet: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $newName,
                    prompt: Text("trips.field.name.placeholder", bundle: .main)
                ) {
                    Text("trips.field.name", bundle: .main)
                }
                TextField(
                    text: $newDestination,
                    prompt: Text("trips.field.destination.placeholder", bundle: .main)
                ) {
                    Text("trips.field.destination", bundle: .main)
                }
                DatePicker(selection: $newStart, displayedComponents: .date) {
                    Text("trips.field.startDate", bundle: .main)
                }
                DatePicker(selection: $newEnd, in: newStart..., displayedComponents: .date) {
                    Text("trips.field.endDate", bundle: .main)
                }
            }
            .navigationTitle(Text("trips.new.title", bundle: .main))
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
                            name: newName,
                            startDate: newStart,
                            endDate: newEnd,
                            destinationName: newDestination
                        )
                        newName = ""
                        newDestination = ""
                        showingNewSheet = false
                    } label: {
                        Text("common.create", bundle: .main)
                    }
                    .disabled(
                        newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || newDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }

    private func delete(_ collection: [Trip], at offsets: IndexSet) {
        for idx in offsets {
            viewModel.delete(collection[idx])
        }
    }

    @ViewBuilder
    private func tripLink(for trip: Trip, nearestID: UUID?) -> some View {
        NavigationLink {
            TripDetailView(
                viewModel: TripDetailViewModel(
                    trip: trip,
                    repository: viewModel.repository,
                    documentStore: viewModel.documentStore,
                    itineraryGenerator: viewModel.itineraryGenerator,
                    itineraryStore: viewModel.itineraryStore,
                    marineService: viewModel.marineService,
                    currencyService: viewModel.currencyService,
                    advisoryService: viewModel.advisoryService
                )
            )
        } label: {
            TripRow(
                trip: trip,
                isNearest: nearestID == trip.id,
                daysUntilStart: nearestID == trip.id ? viewModel.daysUntilNearest()?.1 : nil
            )
        }
    }
}

/// Round 11: only attach `.searchable` once the user has 5+ trips so the
/// search bar doesn't take screen real-estate during early use. Wrapping in
/// a `ViewModifier` keeps `TripsListView`'s body small.
private struct TripsSearchModifier: ViewModifier {
    @Bindable var viewModel: TripsListViewModel

    func body(content: Content) -> some View {
        if viewModel.trips.count >= 5 {
            content.searchable(
                text: $viewModel.searchQuery,
                prompt: Text("trips.search.prompt", bundle: .main)
            )
        } else {
            content
        }
    }
}

private struct TripRow: View {
    let trip: Trip
    var isNearest: Bool = false
    var daysUntilStart: Int?

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(trip.name)
                        .font(.body)
                    if isNearest, let days = daysUntilStart {
                        countdownBadge(days: days)
                    }
                }
                Text(trip.destinationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !trip.packingItems.isEmpty {
                    let packed = trip.packingItems.filter(\.isPacked).count
                    let total = trip.packingItems.count
                    HStack(spacing: 4) {
                        Image(systemName: "suitcase")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(verbatim: "\(packed)/\(total)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(
                        Text(LocalizedStringResource("a11y.trip.packing \(packed) \(total)"))
                    )
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.startDate, format: .dateTime.day().month(.abbreviated))
                    .font(.caption)
                Text(verbatim: "→")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(trip.endDate, format: .dateTime.day().month(.abbreviated))
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func countdownBadge(days: Int) -> some View {
        let key: LocalizedStringKey = {
            if days < 0 { return "trips.countdown.underway" }
            if days == 0 { return "trips.countdown.today" }
            return "trips.countdown.inDays.\(days)"
        }()
        Text(key, bundle: .main)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = trip.coverPhotoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.tint.opacity(0.15))
                Image(systemName: "airplane")
                    .foregroundStyle(.tint)
            }
            .frame(width: 44, height: 44)
        }
    }
}
