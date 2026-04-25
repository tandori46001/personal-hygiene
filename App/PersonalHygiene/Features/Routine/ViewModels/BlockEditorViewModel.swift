import Foundation
import Observation

/// Edits an existing `Block` or builds a new one from form state.
///
/// Time is exposed as `startHour` + `startMinute` for picker UIs but persisted
/// as a single `startMinutesFromMidnight: Int` on `Block`.
@Observable
@MainActor
final class BlockEditorViewModel {

    var title: String
    var category: BlockCategory
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var notes: String
    var notificationLeadMinutes: Int
    var isDeepFocus: Bool

    var locationName: String
    var latitudeText: String
    var longitudeText: String

    let editingBlockID: UUID?

    init() {
        self.title = ""
        self.category = .hygiene
        self.startHour = 7
        self.startMinute = 0
        self.durationMinutes = 30
        self.notes = ""
        self.notificationLeadMinutes = 15
        self.isDeepFocus = false
        self.locationName = ""
        self.latitudeText = ""
        self.longitudeText = ""
        self.editingBlockID = nil
    }

    init(editing block: Block) {
        self.title = block.title
        self.category = block.category
        self.startHour = block.startMinutesFromMidnight / 60
        self.startMinute = block.startMinutesFromMidnight % 60
        self.durationMinutes = block.durationMinutes
        self.notes = block.notes ?? ""
        self.notificationLeadMinutes = block.notificationLeadMinutes
        self.isDeepFocus = block.isDeepFocus
        self.locationName = block.locationName ?? ""
        self.latitudeText = block.latitude.map(Self.formatCoordinate) ?? ""
        self.longitudeText = block.longitude.map(Self.formatCoordinate) ?? ""
        self.editingBlockID = block.id
    }

    var isValid: Bool {
        guard
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            (0..<24).contains(startHour),
            (0..<60).contains(startMinute),
            durationMinutes > 0,
            durationMinutes <= 24 * 60,
            notificationLeadMinutes >= 0
        else {
            return false
        }
        return isLocationValid
    }

    /// Location is valid when it's empty (entirely unset) or both lat + lon parse
    /// to a valid coordinate. Partial / malformed input invalidates the form.
    var isLocationValid: Bool {
        let lat = trimmed(latitudeText)
        let lon = trimmed(longitudeText)
        if lat.isEmpty && lon.isEmpty { return true }
        return parsedLocation != nil
    }

    var parsedLocation: BlockLocation? {
        let lat = trimmed(latitudeText)
        let lon = trimmed(longitudeText)
        guard !lat.isEmpty, !lon.isEmpty else { return nil }
        guard
            let latitude = Double(lat.replacingOccurrences(of: ",", with: ".")),
            let longitude = Double(lon.replacingOccurrences(of: ",", with: "."))
        else {
            return nil
        }
        let trimmedName = trimmed(locationName)
        let candidate = BlockLocation(
            latitude: latitude,
            longitude: longitude,
            displayName: trimmedName.isEmpty ? nil : trimmedName
        )
        return candidate.isValid ? candidate : nil
    }

    var startMinutesFromMidnight: Int {
        startHour * 60 + startMinute
    }

    /// Returns a new `Block` with the current form state.
    /// For edits, the caller should mutate the existing block instead of inserting this one.
    func snapshot() -> Block {
        Block(
            id: editingBlockID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            startMinutesFromMidnight: startMinutesFromMidnight,
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes,
            notificationLeadMinutes: notificationLeadMinutes,
            isDeepFocus: isDeepFocus,
            location: parsedLocation
        )
    }

    /// Apply the form state in-place to an existing `Block` (preferred for edits).
    func apply(to block: Block) {
        block.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        block.category = category
        block.startMinutesFromMidnight = startMinutesFromMidnight
        block.durationMinutes = durationMinutes
        block.notes = notes.isEmpty ? nil : notes
        block.notificationLeadMinutes = notificationLeadMinutes
        block.isDeepFocus = isDeepFocus
        block.location = parsedLocation
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}
