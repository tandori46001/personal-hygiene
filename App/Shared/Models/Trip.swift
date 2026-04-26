import Foundation
import SwiftData

@Model
public final class Trip {
    public var id: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var destinationName: String
    public var destinationLatitude: Double?
    public var destinationLongitude: Double?

    /// JPEG/PNG bytes of an optional cover photo selected via PhotosPicker.
    /// Compressed to ~512KB max before storing.
    @Attribute(.externalStorage)
    public var coverPhotoData: Data?

    /// Free-form packing checklist for the trip. Stored as a single value-type
    /// array so we can persist without introducing a new @Model.
    public var packingItems: [PackingItem]

    @Relationship(deleteRule: .cascade, inverse: \TripMilestone.trip)
    public var milestones: [TripMilestone]

    @Relationship(deleteRule: .cascade, inverse: \TripDocument.trip)
    public var documents: [TripDocument]

    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        destinationName: String,
        destinationLatitude: Double? = nil,
        destinationLongitude: Double? = nil,
        coverPhotoData: Data? = nil,
        packingItems: [PackingItem] = [],
        milestones: [TripMilestone] = [],
        documents: [TripDocument] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.destinationName = destinationName
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.coverPhotoData = coverPhotoData
        self.packingItems = packingItems
        self.milestones = milestones
        self.documents = documents
    }
}

/// A line in the trip packing list. Value type so the parent `Trip` `@Model`
/// owns the collection without needing a child `@Model` table.
public struct PackingItem: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var isPacked: Bool

    public init(id: UUID = UUID(), title: String, isPacked: Bool = false) {
        self.id = id
        self.title = title
        self.isPacked = isPacked
    }
}
