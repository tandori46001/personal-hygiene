import Foundation
import Observation

@Observable
@MainActor
final class TripDetailViewModel {

    private let repository: any TripsRepository
    let documentStore: TripDocumentStore?
    let itineraryGenerator: (any ItineraryGenerator)?
    let marineService: (any MarineWeatherService)?
    let currencyService: (any CurrencyService)?

    var trip: Trip
    var errorMessage: String?

    init(
        trip: Trip,
        repository: any TripsRepository,
        documentStore: TripDocumentStore? = nil,
        itineraryGenerator: (any ItineraryGenerator)? = nil,
        marineService: (any MarineWeatherService)? = nil,
        currencyService: (any CurrencyService)? = nil
    ) {
        self.trip = trip
        self.repository = repository
        self.documentStore = documentStore
        self.itineraryGenerator = itineraryGenerator
        self.marineService = marineService
        self.currencyService = currencyService
    }

    var hasGeocodedDestination: Bool {
        trip.destinationLatitude != nil && trip.destinationLongitude != nil
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

    func addMilestone(title: String, daysBefore: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let milestone = TripMilestone(title: trimmed, daysBefore: max(0, daysBefore))
            try repository.addMilestone(milestone, to: trip)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMilestone(_ milestone: TripMilestone, title: String, daysBefore: Int, isComplete: Bool) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        milestone.title = trimmed
        milestone.daysBefore = max(0, daysBefore)
        milestone.isComplete = isComplete
        saveEdits()
    }

    func toggleMilestoneCompletion(_ milestone: TripMilestone) {
        milestone.isComplete.toggle()
        saveEdits()
    }

    func deleteMilestone(_ milestone: TripMilestone) {
        do {
            try repository.deleteMilestone(milestone)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDocument(name: String, kind: TripDocumentKind, bytes: Data) {
        guard let store = documentStore else {
            errorMessage = "Document storage unavailable."
            return
        }
        do {
            _ = try store.add(name: name, kind: kind, bytes: bytes, to: trip)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteDocument(_ document: TripDocument) {
        do {
            if let store = documentStore {
                try store.remove(document)
            } else {
                try repository.deleteDocument(document)
            }
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
