import SwiftUI

struct TripsListView: View {
    @Bindable var viewModel: TripsListViewModel

    @State private var showingNewSheet = false
    @State private var newName = ""
    @State private var newDestination = ""
    @State private var newStart = Date()
    @State private var newEnd = Date().addingTimeInterval(7 * 24 * 60 * 60)

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
                    Section {
                        ForEach(upcoming) { trip in
                            tripLink(for: trip)
                        }
                        .onDelete { offsets in delete(upcoming, at: offsets) }
                    } header: {
                        Text("trips.section.upcoming", bundle: .main)
                    }
                }

                if !past.isEmpty {
                    Section {
                        ForEach(past) { trip in
                            tripLink(for: trip)
                                .foregroundStyle(.secondary)
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
        .onAppear { viewModel.reload() }
        .sheet(isPresented: $showingNewSheet) {
            newTripSheet
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
    private func tripLink(for trip: Trip) -> some View {
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
            TripRow(trip: trip)
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name)
                    .font(.body)
                Text(trip.destinationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
