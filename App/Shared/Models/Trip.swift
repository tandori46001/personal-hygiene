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
        self.milestones = milestones
        self.documents = documents
    }
}
