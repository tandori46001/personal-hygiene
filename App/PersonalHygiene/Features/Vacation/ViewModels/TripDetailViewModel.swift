import Foundation
import Observation

@Observable
@MainActor
final class TripDetailViewModel {

    private let repository: any TripsRepository
    let documentStore: TripDocumentStore?
    let itineraryGenerator: (any ItineraryGenerator)?
    let itineraryStore: (any ItineraryStore)?
    let marineService: (any MarineWeatherService)?
    let currencyService: (any CurrencyService)?
    let advisoryService: (any TravelAdvisoryService)?

    var trip: Trip

    /// Editable snapshot of trip's scalar fields. The view binds to these so
    /// pressing Cancel can discard changes without leaking them into the
    /// shared `Trip` model. `commit()` writes the draft back + saves; `revert()`
    /// reloads the draft from the model.
    var draftName: String
    var draftDestination: String
    var draftStartDate: Date
    var draftEndDate: Date

    var errorMessage: String?

    init(
        trip: Trip,
        repository: any TripsRepository,
        documentStore: TripDocumentStore? = nil,
        itineraryGenerator: (any ItineraryGenerator)? = nil,
        itineraryStore: (any ItineraryStore)? = nil,
        marineService: (any MarineWeatherService)? = nil,
        currencyService: (any CurrencyService)? = nil,
        advisoryService: (any TravelAdvisoryService)? = nil
    ) {
        self.trip = trip
        self.repository = repository
        self.documentStore = documentStore
        self.itineraryGenerator = itineraryGenerator
        self.itineraryStore = itineraryStore
        self.marineService = marineService
        self.currencyService = currencyService
        self.advisoryService = advisoryService
        self.draftName = trip.name
        self.draftDestination = trip.destinationName
        self.draftStartDate = trip.startDate
        self.draftEndDate = trip.endDate
    }

    var hasChanges: Bool {
        draftName != trip.name
            || draftDestination != trip.destinationName
            || draftStartDate != trip.startDate
            || draftEndDate != trip.endDate
    }

    func revertDraft() {
        draftName = trip.name
        draftDestination = trip.destinationName
        draftStartDate = trip.startDate
        draftEndDate = trip.endDate
    }

    func commitDraft() {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDest = draftDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedDest.isEmpty else { return }
        trip.name = trimmedName
        trip.destinationName = trimmedDest
        trip.startDate = draftStartDate
        trip.endDate = max(draftStartDate, draftEndDate)
        // Reflect the trimmed values + clamped end date back into the draft so
        // `hasChanges` is false right after a commit.
        draftName = trimmedName
        draftDestination = trimmedDest
        draftEndDate = trip.endDate
        saveEdits()
    }

    var advisoryLink: TravelAdvisoryLink? {
        advisoryService?.advisory(forDestination: trip.destinationName)
    }

    /// Multi-source advisory list (round 10): every authoritative foreign-
    /// affairs source returns one entry. Empty when no advisory service is
    /// configured (e.g. previews / certain tests).
    var advisoryLinks: [TravelAdvisoryLink] {
        advisoryService?.advisories(forDestination: trip.destinationName) ?? []
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

    // MARK: - Cover photo

    /// Compress + store the cover photo. Caller is responsible for converting
    /// the picked PhotosPicker selection into JPEG/PNG bytes.
    func updateCoverPhoto(_ data: Data?) {
        trip.coverPhotoData = data
        saveEdits()
    }

    // MARK: - Packing list

    var sortedPackingItems: [PackingItem] {
        trip.packingItems.sorted { lhs, rhs in
            if lhs.isPacked == rhs.isPacked {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return !lhs.isPacked && rhs.isPacked
        }
    }

    var packedCount: Int { trip.packingItems.filter(\.isPacked).count }

    func addPackingItem(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        trip.packingItems.append(PackingItem(title: trimmed))
        saveEdits()
    }

    func togglePackingItem(_ item: PackingItem) {
        guard let idx = trip.packingItems.firstIndex(where: { $0.id == item.id }) else { return }
        trip.packingItems[idx].isPacked.toggle()
        saveEdits()
    }

    func deletePackingItem(_ item: PackingItem) {
        trip.packingItems.removeAll { $0.id == item.id }
        saveEdits()
    }
}
