import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        let repository = SwiftDataRoutineRepository(context: modelContext)

        Group {
            if hasCompletedOnboarding {
                MainTabs(repository: repository)
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

    private let notificationService = UserNotificationsService()

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

            SettingsView(
                viewModel: SettingsViewModel(
                    service: notificationService,
                    coordinator: NotificationCoordinator(
                        repository: repository,
                        service: notificationService
                    )
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
            try? await NotificationCoordinator(
                repository: repository,
                service: notificationService
            ).refreshForToday()
        }
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
