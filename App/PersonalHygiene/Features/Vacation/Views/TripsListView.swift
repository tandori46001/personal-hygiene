import SwiftUI

struct TripsListView: View {
    @Bindable var viewModel: TripsListViewModel

    @State private var showingNewSheet = false
    @State private var newName = ""
    @State private var newDestination = ""
    @State private var newStart = Date()
    @State private var newEnd = Date().addingTimeInterval(7 * 24 * 60 * 60)

    var body: some View {
        NavigationStack {
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
                    ForEach(viewModel.trips) { trip in
                        TripRow(trip: trip)
                    }
                    .onDelete(perform: delete)
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

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.delete(viewModel.trips[idx])
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack {
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
                Text(trip.endDate, format: .dateTime.day().month(.abbreviated))
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
