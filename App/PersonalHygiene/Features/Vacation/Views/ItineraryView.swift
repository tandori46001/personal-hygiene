import SwiftUI

struct ItineraryView: View {

    let trip: Trip
    let generator: any ItineraryGenerator

    @State private var itinerary: TripItinerary?
    @State private var errorMessage: String?
    @State private var isGenerating = false

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
            itinerary = try await generator.generate(for: trip)
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }
}
