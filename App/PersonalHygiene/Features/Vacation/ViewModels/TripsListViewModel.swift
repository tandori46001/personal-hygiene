import Foundation
import Observation

@Observable
@MainActor
final class TripsListViewModel {

    let repository: any TripsRepository

    var trips: [Trip] = []
    var errorMessage: String?

    init(repository: any TripsRepository) {
        self.repository = repository
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
