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
    /// Round-20 slice T3.12: year filter for the past-trips section. `nil` =
    /// "all years". The chip row is hidden if past trips span fewer than two
    /// distinct years (no point filtering one year).
    @State private var pastTripsYearFilter: Int?

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
                                    Button {
                                        // Round-19 slice T4.18: shortcut for the most-common
                                        // recurring-trip pattern.
                                        viewModel.duplicateToNextYear(trip)
                                    } label: {
                                        Label {
                                            Text("trips.action.duplicateNextYear", bundle: .main)
                                        } icon: {
                                            Image(systemName: "calendar.badge.plus")
                                        }
                                    }
                                    .tint(.purple)
                                }
                        }
                        .onDelete { offsets in delete(upcoming, at: offsets) }
                    } header: {
                        Text("trips.section.upcoming", bundle: .main)
                    }
                }

                if !past.isEmpty {
                    let availableYears = Self.distinctYears(in: past)
                    let filteredPast = pastTripsYearFilter
                        .map { year in past.filter { Calendar.current.component(.year, from: $0.startDate) == year } }
                        ?? past
                    Section {
                        // Round-20 slice T3.12: year chips. Hidden when there's
                        // only one year of past trips — chip row would be noise.
                        if availableYears.count >= 2 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    yearChip(label: "common.all", year: nil)
                                    ForEach(availableYears, id: \.self) { year in
                                        yearChip(label: nil, year: year)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        ForEach(filteredPast) { trip in
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
                        .onDelete { offsets in delete(filteredPast, at: offsets) }
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
                DismissingDatePicker(selection: $newStart) {
                    Text("trips.field.startDate", bundle: .main)
                }
                DismissingDatePicker(selection: $newEnd, minimumDate: newStart) {
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

    /// Round-20 slice T3.12: chip used by the past-trips year filter row.
    /// Pass `year: nil` for the "All" reset chip.
    @ViewBuilder
    private func yearChip(label: LocalizedStringKey?, year: Int?) -> some View {
        Button {
            pastTripsYearFilter = year
        } label: {
            Group {
                if let label {
                    Text(label, bundle: .main)
                } else if let year {
                    Text(verbatim: String(year))
                }
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(pastTripsYearFilter == year ? .accentColor : .secondary)
    }

    /// Round-20 slice T3.12: distinct years (descending) of the supplied trips.
    static func distinctYears(in trips: [Trip], calendar: Calendar = .autoupdatingCurrent) -> [Int] {
        let years = trips.map { calendar.component(.year, from: $0.startDate) }
        return Array(Set(years)).sorted(by: >)
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
        HStack(alignment: .top, spacing: 12) {
            thumbnail
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    if isNearest, let days = daysUntilStart {
                        countdownBadge(days: days)
                    }
                    Text(trip.startDate, format: .dateTime.day().month(.abbreviated))
                    Text(verbatim: "→")
                        .accessibilityHidden(true)
                    Text(trip.endDate, format: .dateTime.day().month(.abbreviated))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                if !trip.destinationName.isEmpty {
                    Text(trip.destinationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
            Spacer(minLength: 0)
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
