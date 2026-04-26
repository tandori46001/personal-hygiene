import SwiftData
import SwiftUI
import UserNotifications

@main
struct PersonalHygieneApp: App {

    let modelContainer: ModelContainer
    private let notificationDelegate = NotificationActionHandler()

    init() {
        // UI tests pass `-uiTestReset` to launch on a clean in-memory container,
        // so flows like onboarding can be exercised deterministically without
        // wiping the user's real on-disk store.
        let isUITest = CommandLine.arguments.contains("-uiTestReset")
        if isUITest {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
        do {
            self.modelContainer =
                isUITest
                ? try AppModelContainer.makeInMemory()
                : try AppModelContainer.makeProduction()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        UNUserNotificationCenter.current().delegate = notificationDelegate
        NotificationCategoryRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
