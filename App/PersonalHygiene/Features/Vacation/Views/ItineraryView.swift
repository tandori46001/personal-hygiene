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
                ForEach(Array(itinerary.days.enumerated()), id: \.offset) { offset, day in
                    Section {
                        ForEach(day.activities, id: \.self) { activity in
                            Text(verbatim: activity)
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Text(verbatim: day.title)
                            // Round-20 slice T3.14: relative-day marker so the
                            // user sees how far each itinerary day is from
                            // today. T-3 = three days from today; D+1 = one day
                            // after trip start; ✈ = trip in progress today.
                            if let marker = Self.dayMarker(forIndex: offset, tripStart: trip.startDate) {
                                Text(verbatim: marker)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
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

    /// Round-20 slice T3.14: relative-day marker for the supplied day index
    /// vs `tripStart`. Returns `nil` when the trip starts today (any day-0
    /// marker would be visual noise) or when the index can't be projected
    /// onto a calendar date. Format:
    /// - `T-N` for days N before trip start (countdown)
    /// - `D+N` for days N after trip start (in-trip)
    /// - `✈` for the start day itself
    static func dayMarker(
        forIndex index: Int,
        tripStart: Date,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> String? {
        let dayOfTrip = calendar.date(byAdding: .day, value: index, to: tripStart) ?? tripStart
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: dayOfTrip)
        guard let delta = calendar.dateComponents([.day], from: today, to: target).day else { return nil }
        if delta == 0 { return "✈" }
        if delta < 0 { return "D+\(-delta)" }
        return "T-\(delta)"
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
