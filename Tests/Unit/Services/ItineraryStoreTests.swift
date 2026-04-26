import XCTest

@testable import PersonalHygiene

final class ItineraryStoreTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ItineraryStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testFileStore_saveLoadRoundTrip() {
        let store = FileItineraryStore(directory: tempDir)
        let id = UUID()
        let itinerary = TripItinerary(
            summary: "3-day plan",
            days: [
                TripItinerary.Day(title: "Day 1", activities: ["Walk", "Lunch"]),
                TripItinerary.Day(title: "Day 2", activities: ["Beach"]),
            ]
        )

        XCTAssertNil(store.load(for: id))
        store.save(itinerary, for: id)
        XCTAssertEqual(store.load(for: id), itinerary)
    }

    func testFileStore_overwritesPriorEntry() {
        let store = FileItineraryStore(directory: tempDir)
        let id = UUID()
        let first = TripItinerary(summary: "v1", days: [])
        let second = TripItinerary(summary: "v2", days: [TripItinerary.Day(title: "D1", activities: ["x"])])

        store.save(first, for: id)
        store.save(second, for: id)
        XCTAssertEqual(store.load(for: id), second)
    }

    func testFileStore_remove() {
        let store = FileItineraryStore(directory: tempDir)
        let id = UUID()
        store.save(TripItinerary(summary: "s", days: []), for: id)
        store.remove(for: id)
        XCTAssertNil(store.load(for: id))
    }

    func testFileStore_isolatesPerTripID() {
        let store = FileItineraryStore(directory: tempDir)
        let idA = UUID()
        let idB = UUID()
        let itinA = TripItinerary(summary: "A", days: [])
        let itinB = TripItinerary(summary: "B", days: [])
        store.save(itinA, for: idA)
        store.save(itinB, for: idB)
        XCTAssertEqual(store.load(for: idA), itinA)
        XCTAssertEqual(store.load(for: idB), itinB)
    }

    func testInMemoryStore_roundTrip() {
        let store = InMemoryItineraryStore()
        let id = UUID()
        XCTAssertNil(store.load(for: id))
        let itinerary = TripItinerary(summary: "x", days: [])
        store.save(itinerary, for: id)
        XCTAssertEqual(store.load(for: id), itinerary)
        store.remove(for: id)
        XCTAssertNil(store.load(for: id))
    }
}
