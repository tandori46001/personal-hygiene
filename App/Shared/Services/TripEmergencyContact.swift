import Foundation

/// Round-14 slice 14: emergency contact entry attached to a trip. Stored
/// JSON-encoded on `Trip.emergencyContactsJSON` so we avoid another schema
/// migration. Phone numbers are kept as free-form strings — formatting
/// varies by country and we don't want to validate aggressively.
public struct TripEmergencyContact: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var label: String
    public var phone: String
    public var notes: String?

    public init(
        id: UUID = UUID(),
        label: String,
        phone: String,
        notes: String? = nil
    ) {
        self.id = id
        self.label = label
        self.phone = phone
        self.notes = notes
    }
}
