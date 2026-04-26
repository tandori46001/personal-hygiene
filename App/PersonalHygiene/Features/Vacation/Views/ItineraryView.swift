import SwiftUI

struct ItineraryView: View {

    let trip: Trip
    let generator: any ItineraryGenerator
    let store: (any ItineraryStore)?

    @State private var itinerary: TripItinerary?
    @State private var errorMessage: String?
    @State private var isGenerating = false

    init(trip: Trip, generator: any ItineraryGenerator, store: (any ItineraryStore)? = nil) {
        self.trip = trip
        self.generator = generator
        self.store = store
    }

    var body: some View {
        Form {
            if isGenerating {
                Section {
                    HStack {
                        ProgressView()
                        Text("trip.itinerary.generating", bundle: .main)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage, onDismiss: { self.errorMessage = nil })
                }
                Section {
                    generateButton
                }
            } else if let itinerary {
                Section {
                    Text(verbatim: itinerary.summary)
                }
                ForEach(Array(itinerary.days.enumerated()), id: \.offset) { _, day in
                    Section {
                        ForEach(day.activities, id: \.self) { activity in
                            Text(verbatim: activity)
                        }
                    } header: {
                        Text(verbatim: day.title)
                    }
                }
                Section {
                    generateButton
                }
            } else {
                Section {
                    ContentUnavailableView {
                        Label {
                            Text("trip.itinerary.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "wand.and.stars")
                        }
                    } description: {
                        Text("trip.itinerary.empty.description", bundle: .main)
                    }
                }
                Section {
                    generateButton
                }
            }
        }
        .navigationTitle(Text("trip.itinerary.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if itinerary == nil, let cached = store?.load(for: trip.id) {
                itinerary = cached
            }
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            Label {
                Text("trip.itinerary.action.generate", bundle: .main)
            } icon: {
                Image(systemName: "wand.and.stars")
            }
        }
        .disabled(isGenerating)
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        do {
            let result = try await generator.generate(for: trip)
            itinerary = result
            store?.save(result, for: trip.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }
}
