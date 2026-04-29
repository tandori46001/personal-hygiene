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
    var draftDestinationLatitude: Double?
    var draftDestinationLongitude: Double?
    var draftStartDate: Date
    var draftEndDate: Date
    /// Round-12 slice 9: editable notes draft. Round-trips like the other
    /// scalar fields — Cancel reverts, Save writes back through
    /// `TripsRepository.upsert` via `commitDraft()`.
    var draftNotes: String
    /// Round-12 slice 7: filter applied to the packing list. `nil` shows all
    /// items; otherwise filters by category. Stored on the view model so the
    /// pick survives a sheet dismissal.
    var packingCategoryFilter: PackingCategory?

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
        self.draftDestinationLatitude = trip.destinationLatitude
        self.draftDestinationLongitude = trip.destinationLongitude
        self.draftStartDate = trip.startDate
        self.draftEndDate = trip.endDate
        self.draftNotes = trip.notes
    }

    var hasChanges: Bool {
        draftName != trip.name
            || draftDestination != trip.destinationName
            || draftDestinationLatitude != trip.destinationLatitude
            || draftDestinationLongitude != trip.destinationLongitude
            || draftStartDate != trip.startDate
            || draftEndDate != trip.endDate
            || draftNotes != trip.notes
    }

    func revertDraft() {
        draftName = trip.name
        draftDestination = trip.destinationName
        draftDestinationLatitude = trip.destinationLatitude
        draftDestinationLongitude = trip.destinationLongitude
        draftStartDate = trip.startDate
        draftEndDate = trip.endDate
        draftNotes = trip.notes
    }

    func commitDraft() {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDest = draftDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedDest.isEmpty else { return }
        trip.name = trimmedName
        trip.destinationName = trimmedDest
        trip.destinationLatitude = draftDestinationLatitude
        trip.destinationLongitude = draftDestinationLongitude
        trip.startDate = draftStartDate
        trip.endDate = max(draftStartDate, draftEndDate)
        trip.notes = draftNotes
        // Reflect the trimmed values + clamped end date back into the draft so
        // `hasChanges` is false right after a commit.
        draftName = trimmedName
        draftDestination = trimmedDest
        draftEndDate = trip.endDate
        saveEdits()
    }

    // MARK: - Round 12 helpers

    /// Round-12 slice 7: packing items filtered by the optional `packingCategoryFilter`.
    var filteredSortedPackingItems: [PackingItem] {
        guard let filter = packingCategoryFilter else { return sortedPackingItems }
        return sortedPackingItems.filter { $0.category == filter }
    }

    /// Round-12 slice 11: completion across packing + milestones, normalized
    /// to 0...1. Returns `nil` when the trip has nothing to track yet.
    func completionFraction() -> Double? {
        let packTotal = trip.packingItems.count
        let msTotal = trip.milestones.count
        let denominator = packTotal + msTotal
        guard denominator > 0 else { return nil }
        let packed = trip.packingItems.filter(\.isPacked).count
        let msDone = trip.milestones.filter(\.isComplete).count
        return Double(packed + msDone) / Double(denominator)
    }

    /// Round-12 slice 10: capture the user's most-recent currency conversions
    /// onto the trip itself, so when archived the trip carries a printable
    /// snapshot. No-op when the recents store is empty.
    func captureCurrencySnapshot() {
        let recents = RecentConversionsStore.recent()
        guard !recents.isEmpty else { return }
        let payload = try? JSONEncoder().encode(recents)
        guard let data = payload, let str = String(data: data, encoding: .utf8) else { return }
        trip.currencySnapshotJSON = str
        saveEdits()
    }

    /// Round-12 slice 14: archive the trip — convenience for "Trip done".
    /// Shifts `endDate` to yesterday so it falls into the Past Trips section,
    /// captures the currency snapshot, and saves. Round-13 slice 3: snapshot
    /// always writes, even when recents are empty (sentinel `[]` JSON).
    func archiveNow(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
            ?? now
        if trip.endDate >= calendar.startOfDay(for: now) {
            trip.endDate = yesterday
            draftEndDate = yesterday
        }
        captureCurrencySnapshotWithFallback()
    }

    /// Round-12 slice 14: whether the trip is still upcoming/active (vs already
    /// past). Drives the visibility of the "Archive now" toolbar action.
    func isStillActive(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> Bool {
        calendar.startOfDay(for: trip.endDate) >= calendar.startOfDay(for: now)
    }

    var advisoryLink: TravelAdvisoryLink? {
        advisoryService?.advisory(forDestination: trip.destinationName)
    }

    /// Multi-source advisory list (round 10): every authoritative foreign-
    /// affairs source returns one entry. Empty when no advisory service is
    /// configured (e.g. previews / certain tests). Round 11: respects the
    /// user's preferred lead source from `PreferredAdvisorySourceStore`.
    var advisoryLinks: [TravelAdvisoryLink] {
        let raw = advisoryService?.advisories(forDestination: trip.destinationName) ?? []
        return PreferredAdvisorySourceStore.reorder(
            raw,
            preferred: PreferredAdvisorySourceStore.preferred()
        )
    }

    var hasGeocodedDestination: Bool {
        trip.destinationLatitude != nil && trip.destinationLongitude != nil
    }

    var sortedMilestones: [TripMilestone] {
        trip.milestones.sorted { $0.daysBefore > $1.daysBefore }
    }

    /// Round-11: surface the next-due, still-incomplete milestone for the
    /// detail-view's prominent header card. Returns `nil` when every
    /// milestone is complete or there are none. "Next" = the milestone with
    /// the *smallest* `daysBefore` among those whose trigger day is still in
    /// the future (or today) — that's the one closest to firing. Past-due
    /// milestones are skipped because they should already be marked complete.
    func nextDueMilestone(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> TripMilestone? {
        let today = calendar.startOfDay(for: now)
        let tripStart = calendar.startOfDay(for: trip.startDate)
        let candidates = trip.milestones.filter { milestone in
            guard !milestone.isComplete else { return false }
            guard let triggerDay = calendar.date(
                byAdding: .day,
                value: -milestone.daysBefore,
                to: tripStart
            ) else { return false }
            return calendar.startOfDay(for: triggerDay) >= today
        }
        // Smallest daysBefore = closest to the trip start = soonest to fire.
        return candidates.min { lhs, rhs in
            lhs.daysBefore < rhs.daysBefore
        }
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

    /// Round-11 bulk action: mark every packing item as packed. No-op when
    /// the list is empty.
    func markAllPacked() {
        guard !trip.packingItems.isEmpty else { return }
        for index in trip.packingItems.indices {
            trip.packingItems[index].isPacked = true
        }
        saveEdits()
    }

    /// Round-11 bulk action: reset every packing item to unpacked. Useful
    /// when reusing a packing template across trips.
    func resetAllPacking() {
        guard !trip.packingItems.isEmpty else { return }
        for index in trip.packingItems.indices {
            trip.packingItems[index].isPacked = false
        }
        saveEdits()
    }
}
