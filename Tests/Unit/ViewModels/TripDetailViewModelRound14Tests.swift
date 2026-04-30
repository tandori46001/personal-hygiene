@testable import PersonalHygiene
import SwiftData
@preconcurrency import XCTest

@MainActor
final class TripDetailViewModelRound14Tests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataTripsRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TripMilestone.self, TripDocument.self,
            configurations: config
        )
        repository = SwiftDataTripsRepository(context: container.mainContext)
    }

    override func tearDown() {
        repository = nil
        container = nil
    }

    private func makeViewModel(_ trip: Trip) -> TripDetailViewModel {
        try? repository.upsert(trip)
        return TripDetailViewModel(trip: trip, repository: repository)
    }

    func test_expensesByCurrency_groupsCorrectly() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y"
        )
        let viewModel = makeViewModel(trip)
        viewModel.addExpense(label: "Hotel", amount: 100, currencyCode: "USD")
        viewModel.addExpense(label: "Meal", amount: 25, currencyCode: "USD")
        viewModel.addExpense(label: "Cab", amount: 30, currencyCode: "EUR")
        let totals = viewModel.expensesByCurrency
        XCTAssertEqual(totals["USD"], 125)
        XCTAssertEqual(totals["EUR"], 30)
    }

    func test_emergencyContacts_addAndDelete() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y"
        )
        let viewModel = makeViewModel(trip)
        viewModel.addEmergencyContact(label: "Embassy", phone: "+1 555 1234")
        XCTAssertEqual(viewModel.emergencyContacts.count, 1)
        let added = viewModel.emergencyContacts.first!
        viewModel.deleteEmergencyContact(added)
        XCTAssertTrue(viewModel.emergencyContacts.isEmpty)
    }

    func test_roundTripCO2_returnsNilWithoutGeocode() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y"
        )
        let viewModel = makeViewModel(trip)
        let home = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Madrid")
        XCTAssertNil(viewModel.roundTripCO2Kg(home: home))
    }

    func test_roundTripCO2_madridToTokyo() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Tokyo",
            destinationLatitude: 35.6762,
            destinationLongitude: 139.6503
        )
        let viewModel = makeViewModel(trip)
        let home = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Madrid")
        let kg = viewModel.roundTripCO2Kg(home: home)
        XCTAssertNotNil(kg)
        XCTAssertEqual(kg ?? 0, 5_500, accuracy: 100)
    }
}
