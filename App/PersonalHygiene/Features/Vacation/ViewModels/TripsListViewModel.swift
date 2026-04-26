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
        return trips.filter { calendar.startOfDay(for: $0.endDate) >= today }
    }

    func pastTrips(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> [Trip] {
        let today = calendar.startOfDay(for: now)
        return trips
            .filter { calendar.startOfDay(for: $0.endDate) < today }
            .sorted { $0.endDate > $1.endDate }
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
}
