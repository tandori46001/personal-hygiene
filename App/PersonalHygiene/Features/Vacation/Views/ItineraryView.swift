import SwiftUI

struct ItineraryView: View {

    let trip: Trip
    let generator: any ItineraryGenerator
    let store: (any ItineraryStore)?

    @State private var itinerary: TripItinerary?
    @State private var errorMessage: String?
    @State private var isGenerating = false
    @State private var sharePayload: SharePayload?

    private struct SharePayload: Identifiable {
        let id = UUID()
        let text: String
    }

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
        .toolbar {
            if let itinerary {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sharePayload = SharePayload(text: Self.plainText(for: itinerary, trip: trip))
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text("trip.itinerary.action.share", bundle: .main))
                }
            }
        }
        .onAppear {
            if itinerary == nil, let cached = store?.load(for: trip.id) {
                itinerary = cached
            }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
    }

    static func plainText(for itinerary: TripItinerary, trip: Trip) -> String {
        var lines: [String] = []
        lines.append(trip.name)
        if !trip.destinationName.isEmpty {
            lines.append(trip.destinationName)
        }
        lines.append("")
        lines.append(itinerary.summary)
        for day in itinerary.days {
            lines.append("")
            lines.append(day.title)
            for activity in day.activities {
                lines.append("• \(activity)")
            }
        }
        return lines.joined(separator: "\n")
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
