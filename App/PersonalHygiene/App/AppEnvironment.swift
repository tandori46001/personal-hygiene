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
    let notificationService: any NotificationService
    let medicationService: any MedicationService
    let sleepService: any SleepService
    let contactsService: any ContactsService
    let travelTimeService: any TravelTimeService
    let homeStore: HomeLocationStore

    init(modelContext: ModelContext) {
        self.routineRepository = SwiftDataRoutineRepository(context: modelContext)
        self.hydrationService = SwiftDataHydrationService(context: modelContext)
        self.housekeepingService = SwiftDataHousekeepingService(context: modelContext)
        self.tripsRepository = SwiftDataTripsRepository(context: modelContext)
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
}
