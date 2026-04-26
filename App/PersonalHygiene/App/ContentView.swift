import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        let repository = SwiftDataRoutineRepository(context: modelContext)
        let hydrationService = SwiftDataHydrationService(context: modelContext)

        Group {
            if hasCompletedOnboarding {
                MainTabs(repository: repository, hydrationService: hydrationService)
            } else {
                OnboardingView(
                    repository: repository,
                    onComplete: { hasCompletedOnboarding = true }
                )
            }
        }
    }
}

private struct MainTabs: View {
    let repository: any RoutineRepository
    let hydrationService: any HydrationService

    private let notificationService = UserNotificationsService()
    private let medicationService = HealthKitMedicationService()
    private let sleepService = HealthKitSleepService()
    private let travelTimeService: any TravelTimeService = MKDirectionsTravelTimeService()
    private let homeStore = HomeLocationStore()

    private func makeCoordinator() -> NotificationCoordinator {
        NotificationCoordinator(
            repository: repository,
            service: notificationService,
            travelTimeService: travelTimeService,
            homeLocation: homeStore.location
        )
    }

    var body: some View {
        TabView {
            TodayView(viewModel: TodayViewModel(repository: repository))
                .tabItem {
                    Label {
                        Text("tab.today", bundle: .main)
                    } icon: {
                        Image(systemName: "sun.max")
                    }
                }

            TemplateListView(
                viewModel: TemplateListViewModel(repository: repository),
                repository: repository
            )
            .tabItem {
                Label {
                    Text("tab.templates", bundle: .main)
                } icon: {
                    Image(systemName: "calendar")
                }
            }

            MedicationComplianceView(
                viewModel: MedicationComplianceViewModel(
                    service: medicationService,
                    repository: repository
                )
            )
            .tabItem {
                Label {
                    Text("tab.medication", bundle: .main)
                } icon: {
                    Image(systemName: "pills")
                }
            }

            SleepDashboardView(
                viewModel: SleepDashboardViewModel(service: sleepService)
            )
            .tabItem {
                Label {
                    Text("tab.sleep", bundle: .main)
                } icon: {
                    Image(systemName: "moon")
                }
            }

            HydrationDashboardView(
                viewModel: HydrationDashboardViewModel(service: hydrationService)
            )
            .tabItem {
                Label {
                    Text("tab.hydration", bundle: .main)
                } icon: {
                    Image(systemName: "drop")
                }
            }

            SettingsView(
                viewModel: SettingsViewModel(
                    service: notificationService,
                    coordinator: makeCoordinator()
                )
            )
            .tabItem {
                Label {
                    Text("tab.settings", bundle: .main)
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            // Best-effort refresh on launch; silently ignore errors here —
            // the user can retry from Settings if anything goes wrong.
            try? await makeCoordinator().refreshForToday()
        }
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
