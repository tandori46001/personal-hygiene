import Foundation
import Observation

@Observable
@MainActor
final class TripsListViewModel {

    let repository: any TripsRepository
    let documentStore: TripDocumentStore?
    let itineraryGenerator: (any ItineraryGenerator)?
    let itineraryStore: (any ItineraryStore)?
    let marineService: (any MarineWeatherService)?
    let currencyService: (any CurrencyService)?
    let advisoryService: (any TravelAdvisoryService)?

    var trips: [Trip] = []
    var errorMessage: String?

    /// Free-form search term applied to `name` + `destinationName` (case-
    /// insensitive). Empty string disables filtering. Round-11 surface in
    /// `TripsListView` only renders the `searchable` modifier when there
    /// are 5+ trips so the bar doesn't clutter early on.
    var searchQuery: String = ""

    init(
        repository: any TripsRepository,
        documentStore: TripDocumentStore? = nil,
        itineraryGenerator: (any ItineraryGenerator)? = nil,
        itineraryStore: (any ItineraryStore)? = nil,
        marineService: (any MarineWeatherService)? = nil,
        currencyService: (any CurrencyService)? = nil,
        advisoryService: (any TravelAdvisoryService)? = nil
    ) {
        self.repository = repository
        self.documentStore = documentStore
        self.itineraryGenerator = itineraryGenerator
        self.itineraryStore = itineraryStore
        self.marineService = marineService
        self.currencyService = currencyService
        self.advisoryService = advisoryService
    }

    /// Trips whose end date is on or after `now` (default: today).
    /// Used by `TripsListView` to split active vs past archive.
    func upcomingTrips(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> [Trip] {
        let today = calendar.startOfDay(for: now)
        return filtered(trips.filter { calendar.startOfDay(for: $0.endDate) >= today })
    }

    func pastTrips(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> [Trip] {
        let today = calendar.startOfDay(for: now)
        return filtered(trips
            .filter { calendar.startOfDay(for: $0.endDate) < today }
            .sorted { $0.endDate > $1.endDate })
    }

    /// Pure filter helper exposed for tests. Returns `trips` unchanged when
    /// `searchQuery` is empty, otherwise keeps trips whose `name` or
    /// `destinationName` contains the trimmed query (case-insensitive).
    func filtered(_ trips: [Trip]) -> [Trip] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return trips }
        return trips.filter { trip in
            trip.name.localizedCaseInsensitiveContains(query)
                || trip.destinationName.localizedCaseInsensitiveContains(query)
        }
    }

    func reload() {
        do {
            trips = try repository.allTrips()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(name: String, startDate: Date, endDate: Date, destinationName: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let dest = destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !dest.isEmpty else { return }
        do {
            let trip = Trip(name: trimmed, startDate: startDate, endDate: endDate, destinationName: dest)
            try repository.upsert(trip)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ trip: Trip) {
        do {
            try repository.delete(trip)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Days from `now` to the *closest* upcoming trip's start date. `nil` if
    /// there are no upcoming trips. The list view uses this to badge the
    /// nearest trip with "in N days" / "today" / "underway".
    func daysUntilNearest(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> (Trip, Int)? {
        let upcoming = upcomingTrips(now: now, calendar: calendar)
        guard let nearest = upcoming.min(by: { $0.startDate < $1.startDate }) else { return nil }
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: nearest.startDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        return (nearest, days)
    }

    /// Build a *new* `Trip` cloned from `source` — packing list + milestones
    /// duplicated by value, dates left unchanged for the user to adjust. The
    /// caller must `upsert` the returned trip; the duplicate isn't persisted
    /// until then so `Cancel` from the editor leaves no orphan row behind.
    /// Round 11: the explicit `name` parameter lets the duplicate-confirm
    /// alert pass a user-edited name; falls back to `Copy of <source.name>`.
    static func duplicate(_ source: Trip, name: String? = nil) -> Trip {
        let resolvedName = name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
            ?? "Copy of \(source.name)"
        let copy = Trip(
            name: resolvedName,
            startDate: source.startDate,
            endDate: source.endDate,
            destinationName: source.destinationName
        )
        copy.destinationLatitude = source.destinationLatitude
        copy.destinationLongitude = source.destinationLongitude
        copy.coverPhotoData = source.coverPhotoData
        copy.packingItems = source.packingItems.map { PackingItem(title: $0.title, isPacked: false) }
        return copy
    }

    func duplicate(_ source: Trip, name: String? = nil) {
        do {
            let copy = Self.duplicate(source, name: name)
            try repository.upsert(copy)
            for milestone in source.milestones.sorted(by: { $0.daysBefore > $1.daysBefore }) {
                let cloned = TripMilestone(
                    title: milestone.title,
                    daysBefore: milestone.daysBefore,
                    isComplete: false
                )
                try repository.addMilestone(cloned, to: copy)
            }
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
