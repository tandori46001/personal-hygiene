import Foundation
import SwiftData

@MainActor
public protocol TripsRepository {
    func allTrips() throws -> [Trip]
    func upsert(_ trip: Trip) throws
    func delete(_ trip: Trip) throws
    func addMilestone(_ milestone: TripMilestone, to trip: Trip) throws
    func deleteMilestone(_ milestone: TripMilestone) throws
    func addDocument(_ document: TripDocument, to trip: Trip) throws
    func deleteDocument(_ document: TripDocument) throws
}

@MainActor
public final class SwiftDataTripsRepository: TripsRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func allTrips() throws -> [Trip] {
        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate)])
        return try context.fetch(descriptor)
    }

    public func upsert(_ trip: Trip) throws {
        if trip.modelContext == nil {
            context.insert(trip)
        }
        try context.save()
    }

    public func delete(_ trip: Trip) throws {
        context.delete(trip)
        try context.save()
    }

    public func addMilestone(_ milestone: TripMilestone, to trip: Trip) throws {
        if milestone.modelContext == nil {
            trip.milestones.append(milestone)
        }
        try context.save()
    }

    public func deleteMilestone(_ milestone: TripMilestone) throws {
        context.delete(milestone)
        try context.save()
    }

    public func addDocument(_ document: TripDocument, to trip: Trip) throws {
        if document.modelContext == nil {
            trip.documents.append(document)
        }
        try context.save()
    }

    public func deleteDocument(_ document: TripDocument) throws {
        context.delete(document)
        try context.save()
    }
}
