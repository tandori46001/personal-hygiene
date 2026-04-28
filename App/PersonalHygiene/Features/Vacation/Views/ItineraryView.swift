import SwiftUI

struct ItineraryView: View {

    let trip: Trip
    let generator: any ItineraryGenerator
    let store: (any ItineraryStore)?
    /// Round-22 slice T3.14: forecast bridge. Defaults to the stub so the
    /// surface compiles without WeatherKit entitlement; production code
    /// passes `WeatherKitForecastService()` when iOS 16+ runtime confirms
    /// availability.
    let forecastFetcher: any WeatherForecastFetching

    @State private var itinerary: TripItinerary?
    @State private var errorMessage: String?
    @State private var isGenerating = false
    @State private var sharePayload: SharePayload?
    /// Round-22 slice T3.15: per-day forecasts keyed by `Calendar.startOfDay`.
    @State private var forecastsByDay: [Date: WeatherForecast] = [:]
    /// Round-22 slice T3.18: `true` when the only data we could surface
    /// came from `cachedIgnoringTTL` (offline / fetch failed).
    @State private var forecastIsStale = false
    /// Round-22 slice T3.17: timestamp of the last successful fetch, used
    /// for the "última actualización HH:mm" caption.
    @State private var forecastFetchedAt: Date?
    @State private var forecastErrorBanner: String?

    private struct SharePayload: Identifiable {
        let id = UUID()
        let text: String
    }

    init(
        trip: Trip,
        generator: any ItineraryGenerator,
        store: (any ItineraryStore)? = nil,
        forecastFetcher: any WeatherForecastFetching = StubWeatherForecastService()
    ) {
        self.trip = trip
        self.generator = generator
        self.store = store
        self.forecastFetcher = forecastFetcher
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
                            // Round-22 slice T3.15: forecast chip pulled
                            // from `forecastsByDay` keyed by the index's
                            // calendar day. Stale variant rendered
                            // semi-transparent.
                            if let forecast = self.forecast(forIndex: offset) {
                                ItineraryDayForecastChip(forecast: forecast)
                                    .opacity(forecastIsStale ? 0.55 : 1)
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
                // Round-22 slice T3.17: refresh forecast button + caption.
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        Task { await refreshForecast(force: true) }
                    } label: {
                        Label {
                            Text("trip.itinerary.action.refreshForecast", bundle: .main)
                        } icon: {
                            Image(systemName: "cloud.sun.fill")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 2) {
                // Round-23 slice T3.14: surface fetch failures inline.
                if let banner = forecastErrorBanner {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(verbatim: banner)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
                }
                if let fetchedAt = forecastFetchedAt {
                    Text(
                        "trip.itinerary.forecast.lastUpdated \(forecastCaption(fetchedAt))",
                        bundle: .main
                    )
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(forecastIsStale ? Color.orange : Color.secondary)
                }
            }
            .padding(.bottom, 4)
        }
        .onAppear {
            if itinerary == nil, let cached = store?.load(for: trip.id) {
                itinerary = cached
            }
            Task { await refreshForecast(force: false) }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
    }

    /// Round-22 slice T3.15 (round-23 T1.5: delegated to
    /// `ItineraryForecastBinning` for unit-test coverage). Returns nil when
    /// no forecast was fetched for that calendar day.
    private func forecast(forIndex index: Int) -> WeatherForecast? {
        ItineraryForecastBinning.forecast(forIndex: index, tripStart: trip.startDate, in: forecastsByDay)
    }

    /// Round-22 slices T3.14 + T3.18: fetch forecasts via the injected
    /// fetcher and bin them by `Calendar.startOfDay`. On failure, falls
    /// back to `WeatherForecastCache.cachedIgnoringTTL(...)` so the user
    /// still sees something useful offline (rendered with `forecastIsStale`).
    @MainActor
    private func refreshForecast(force: Bool) async {
        guard let lat = trip.destinationLatitude,
              let lon = trip.destinationLongitude
        else { return }
        let cache = WeatherForecastCache.shared
        if !force, let warm = cache.cached(latitude: lat, longitude: lon) {
            forecastsByDay = ItineraryForecastBinning.bin(warm)
            forecastIsStale = false
            forecastFetchedAt = Date()
            return
        }
        do {
            let days = ItineraryForecastBinning.daysSpanned(from: trip.startDate, to: trip.endDate)
            let fresh = try await forecastFetcher.forecast(latitude: lat, longitude: lon, days: days)
            cache.store(fresh, latitude: lat, longitude: lon)
            forecastsByDay = ItineraryForecastBinning.bin(fresh)
            forecastIsStale = false
            forecastFetchedAt = Date()
            forecastErrorBanner = nil
        } catch {
            if let stale = cache.cachedIgnoringTTL(latitude: lat, longitude: lon) {
                forecastsByDay = ItineraryForecastBinning.bin(stale.forecasts)
                forecastIsStale = true
                forecastFetchedAt = stale.storedAt
            }
            forecastErrorBanner = error.localizedDescription
        }
    }

    private func cachedHit(latitude: Double, longitude: Double) -> [WeatherForecast]? {
        WeatherForecastCache.shared.cached(latitude: latitude, longitude: longitude)
    }

    private func forecastCaption(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
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
