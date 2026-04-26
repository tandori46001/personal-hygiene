import Foundation
import Observation

@Observable
@MainActor
final class TripsListViewModel {

    let repository: any TripsRepository
    let documentStore: TripDocumentStore?
    let itineraryGenerator: (any ItineraryGenerator)?
    let marineService: (any MarineWeatherService)?
    let currencyService: (any CurrencyService)?
    let advisoryService: (any TravelAdvisoryService)?

    var trips: [Trip] = []
    var errorMessage: String?

    init(
        repository: any TripsRepository,
        documentStore: TripDocumentStore? = nil,
        itineraryGenerator: (any ItineraryGenerator)? = nil,
        marineService: (any MarineWeatherService)? = nil,
        currencyService: (any CurrencyService)? = nil,
        advisoryService: (any TravelAdvisoryService)? = nil
    ) {
        self.repository = repository
        self.documentStore = documentStore
        self.itineraryGenerator = itineraryGenerator
        self.marineService = marineService
        self.currencyService = currencyService
        self.advisoryService = advisoryService
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
