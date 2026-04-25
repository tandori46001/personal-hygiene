import Foundation
import SwiftData

/// A single time-blocked item in the user's daily routine.
@Model
public final class Block {
    public var id: UUID
    public var title: String
    public var category: BlockCategory
    public var startMinutesFromMidnight: Int
    public var durationMinutes: Int
    public var notes: String?
    public var notificationLeadMinutes: Int
    public var isDeepFocus: Bool
    /// Optional HealthKit medication concept identifier. Only set when
    /// `category == .medication` and the user has linked the block to a
    /// concept via the editor.
    public var medicationConceptIdentifier: String?

    public var latitude: Double?
    public var longitude: Double?
    public var locationName: String?

    public var template: RoutineTemplate?

    public init(
        id: UUID = UUID(),
        title: String,
        category: BlockCategory,
        startMinutesFromMidnight: Int,
        durationMinutes: Int,
        notes: String? = nil,
        notificationLeadMinutes: Int = 15,
        isDeepFocus: Bool = false,
        medicationConceptIdentifier: String? = nil,
        location: BlockLocation? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.notificationLeadMinutes = notificationLeadMinutes
        self.isDeepFocus = isDeepFocus
        self.medicationConceptIdentifier = medicationConceptIdentifier
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.locationName = location?.displayName
    }

    public var endMinutesFromMidnight: Int {
        startMinutesFromMidnight + durationMinutes
    }

    public var location: BlockLocation? {
        get {
            guard let latitude, let longitude else { return nil }
            return BlockLocation(latitude: latitude, longitude: longitude, displayName: locationName)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
            locationName = newValue?.displayName
        }
    }
}
