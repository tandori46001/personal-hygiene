import SwiftData
import XCTest

@testable import PersonalHygiene

// L001 reminder: every fixture below holds the ModelContainer so the
// ModelContext outlives the helper's stack frame.

@MainActor
final class TripDocumentStoreTests: XCTestCase {

    private struct Fixture {
        let container: ModelContainer
        let store: TripDocumentStore
        let trip: Trip
        let keychain: InMemoryKeychainStore
    }

    private func makeFixture() throws -> Fixture {
        let container = try AppModelContainer.makeInMemory()
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = Trip(
            name: "Mediterráneo",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000),
            destinationName: "Mallorca"
        )
        try repo.upsert(trip)
        let keychain = InMemoryKeychainStore()
        return Fixture(
            container: container,
            store: TripDocumentStore(repository: repo, keychain: keychain),
            trip: trip,
            keychain: keychain
        )
    }

    func test_add_writesBothMetadataAndBytes() throws {
        let fix = try makeFixture()
        let store = fix.store
        let trip = fix.trip
        let keychain = fix.keychain
        let document = try store.add(
            name: "Passport",
            kind: .passport,
            bytes: Data("pdf-bytes".utf8),
            to: trip
        )
        XCTAssertEqual(trip.documents.count, 1)
        XCTAssertEqual(keychain.items.count, 1)
        XCTAssertEqual(try store.bytes(for: document), Data("pdf-bytes".utf8))
    }

    func test_remove_deletesMetadataAndBytes() throws {
        let fix = try makeFixture()
        let document = try fix.store.add(
            name: "Passport",
            kind: .passport,
            bytes: Data("p".utf8),
            to: fix.trip
        )
        try fix.store.remove(document)
        XCTAssertTrue(fix.trip.documents.isEmpty)
        XCTAssertTrue(fix.keychain.items.isEmpty)
    }

    func test_blankNameFallsBackToUntitled() throws {
        let fix = try makeFixture()
        let document = try fix.store.add(name: "  ", kind: .other, bytes: Data("x".utf8), to: fix.trip)
        XCTAssertEqual(document.name, "Untitled")
    }
}
