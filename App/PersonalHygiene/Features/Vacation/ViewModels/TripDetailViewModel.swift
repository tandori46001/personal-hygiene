import Foundation
import Observation

@Observable
@MainActor
final class TripDetailViewModel {

    private let repository: any TripsRepository

    var trip: Trip
    var errorMessage: String?

    init(trip: Trip, repository: any TripsRepository) {
        self.trip = trip
        self.repository = repository
    }

    var sortedMilestones: [TripMilestone] {
        trip.milestones.sorted { $0.daysBefore > $1.daysBefore }
    }

    var sortedDocuments: [TripDocument] {
        trip.documents.sorted { $0.addedAt > $1.addedAt }
    }

    func saveEdits() {
        do {
            try repository.upsert(trip)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMilestone(_ milestone: TripMilestone) {
        do {
            try repository.deleteMilestone(milestone)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteDocument(_ document: TripDocument) {
        do {
            try repository.deleteDocument(document)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// `0` on the day of departure, negative once underway, positive while waiting.
    func daysUntilDeparture(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> Int {
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: trip.startDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }
}
