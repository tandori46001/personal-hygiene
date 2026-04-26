import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        let env = AppEnvironment(modelContext: modelContext)

        Group {
            if hasCompletedOnboarding {
                MainTabs(env: env)
            } else {
                OnboardingView(
                    repository: env.routineRepository,
                    onComplete: { hasCompletedOnboarding = true }
                )
            }
        }
    }
}

private struct MainTabs: View {
    let env: AppEnvironment

    var body: some View {
        TabView {
            TodayView(viewModel: TodayViewModel(repository: env.routineRepository))
                .tabItem {
                    Label {
                        Text("tab.today", bundle: .main)
                    } icon: {
                        Image(systemName: "sun.max")
                    }
                }

            TemplateListView(
                viewModel: TemplateListViewModel(repository: env.routineRepository),
                repository: env.routineRepository
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
                    service: env.medicationService,
                    repository: env.routineRepository
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
                viewModel: SleepDashboardViewModel(service: env.sleepService)
            )
            .tabItem {
                Label {
                    Text("tab.sleep", bundle: .main)
                } icon: {
                    Image(systemName: "moon")
                }
            }

            HydrationDashboardView(
                viewModel: HydrationDashboardViewModel(service: env.hydrationService)
            )
            .tabItem {
                Label {
                    Text("tab.hydration", bundle: .main)
                } icon: {
                    Image(systemName: "drop")
                }
            }

            HousekeepingListView(
                viewModel: HousekeepingListViewModel(service: env.housekeepingService)
            )
            .tabItem {
                Label {
                    Text("tab.housekeeping", bundle: .main)
                } icon: {
                    Image(systemName: "checklist")
                }
            }

            BirthdaysView(
                viewModel: BirthdaysViewModel(service: env.contactsService)
            )
            .tabItem {
                Label {
                    Text("tab.birthdays", bundle: .main)
                } icon: {
                    Image(systemName: "gift")
                }
            }

            TripsListView(
                viewModel: TripsListViewModel(
                    repository: env.tripsRepository,
                    documentStore: env.tripDocumentStore,
                    itineraryGenerator: env.itineraryGenerator,
                    marineService: env.marineService,
                    currencyService: env.currencyService,
                    advisoryService: env.advisoryService
                )
            )
            .tabItem {
                Label {
                    Text("tab.trips", bundle: .main)
                } icon: {
                    Image(systemName: "airplane")
                }
            }

            SettingsView(
                viewModel: SettingsViewModel(
                    service: env.notificationService,
                    coordinator: env.makeNotificationCoordinator()
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
            try? await env.makeNotificationCoordinator().refreshForToday()
            try? await env.makeTripMilestoneScheduler().refresh()
        }
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
