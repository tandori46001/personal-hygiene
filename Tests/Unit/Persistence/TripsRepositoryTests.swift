import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class TripsRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repo: SwiftDataTripsRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        repo = SwiftDataTripsRepository(context: container.mainContext)
    }

    override func tearDown() async throws {
        repo = nil
        container = nil
        try await super.tearDown()
    }

    private func tripFixture() -> Trip {
        Trip(
            name: "Mediterráneo",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000),
            destinationName: "Mallorca"
        )
    }

    func test_upsert_andAllTrips_returnsTrip() throws {
        let trip = tripFixture()
        try repo.upsert(trip)
        let trips = try repo.allTrips()
        XCTAssertEqual(trips.count, 1)
        XCTAssertEqual(trips.first?.name, "Mediterráneo")
    }

    func test_addMilestone_appendsAndPersists() throws {
        let trip = tripFixture()
        try repo.upsert(trip)
        let milestone = TripMilestone(title: "Buy currency", daysBefore: 7)
        try repo.addMilestone(milestone, to: trip)
        XCTAssertEqual(trip.milestones.count, 1)
    }

    func test_addDocument_appendsAndPersists() throws {
        let trip = tripFixture()
        try repo.upsert(trip)
        let doc = TripDocument(name: "Passport", kind: .passport, keychainItemID: "kc-1")
        try repo.addDocument(doc, to: trip)
        XCTAssertEqual(trip.documents.count, 1)
    }

    func test_delete_cascadesMilestonesAndDocuments() throws {
        let trip = tripFixture()
        try repo.upsert(trip)
        try repo.addMilestone(TripMilestone(title: "Pack", daysBefore: 1), to: trip)
        try repo.addDocument(
            TripDocument(name: "Passport", kind: .passport, keychainItemID: "kc-1"),
            to: trip
        )
        try repo.delete(trip)

        XCTAssertTrue(try repo.allTrips().isEmpty)
        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<TripMilestone>()).isEmpty)
        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<TripDocument>()).isEmpty)
    }
}
