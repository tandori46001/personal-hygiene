import Foundation
import SwiftData
import SwiftUI

/// Aggregates the app-wide services so views can read them via `@Environment`
/// instead of constructing each one inline. Keeps `ContentView` flat.
@MainActor
struct AppEnvironment {

    let routineRepository: any RoutineRepository
    let hydrationService: any HydrationService
    let housekeepingService: any HousekeepingService
    let tripsRepository: any TripsRepository
    let tripDocumentStore: TripDocumentStore
    let itineraryGenerator: any ItineraryGenerator
    let marineService: any MarineWeatherService
    let notificationService: any NotificationService
    let medicationService: any MedicationService
    let sleepService: any SleepService
    let contactsService: any ContactsService
    let travelTimeService: any TravelTimeService
    let homeStore: HomeLocationStore

    init(modelContext: ModelContext) {
        let trips = SwiftDataTripsRepository(context: modelContext)
        self.routineRepository = SwiftDataRoutineRepository(context: modelContext)
        self.hydrationService = SwiftDataHydrationService(context: modelContext)
        self.housekeepingService = SwiftDataHousekeepingService(context: modelContext)
        self.tripsRepository = trips
        self.tripDocumentStore = TripDocumentStore(repository: trips, keychain: SecKeychainStore())
        self.itineraryGenerator = Self.makeItineraryGenerator()
        self.marineService = OpenMeteoMarineService()
        self.notificationService = UserNotificationsService()
        self.medicationService = HealthKitMedicationService()
        self.sleepService = HealthKitSleepService()
        self.contactsService = CNContactsService()
        self.travelTimeService = MKDirectionsTravelTimeService()
        self.homeStore = HomeLocationStore()
    }

    func makeNotificationCoordinator(calendar: Calendar = .autoupdatingCurrent) -> NotificationCoordinator {
        NotificationCoordinator(
            repository: routineRepository,
            service: notificationService,
            travelTimeService: travelTimeService,
            homeLocation: homeStore.location,
            calendar: calendar
        )
    }

    func makeTripMilestoneScheduler(calendar: Calendar = .autoupdatingCurrent) -> TripMilestoneScheduler {
        TripMilestoneScheduler(
            repository: tripsRepository,
            service: notificationService,
            calendar: calendar
        )
    }

    private static func makeItineraryGenerator() -> any ItineraryGenerator {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return FoundationModelsItineraryGenerator()
        }
        #endif
        return StubItineraryGenerator()
    }
}
