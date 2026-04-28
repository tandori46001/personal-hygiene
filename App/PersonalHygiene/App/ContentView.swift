import SwiftData
import SwiftUI
import UserNotifications

enum AppTab: Hashable {
    case today, templates, medication, sleep, hydration, housekeeping, birthdays, trips, settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("whatsNew.lastSeenCommitSHA") private var lastSeenCommitSHA = ""
    @AppStorage("settings.theme") private var themeOverride: String = "system"
    @State private var showingWhatsNewAuto = false
    @Environment(\.scenePhase) private var scenePhase

    /// Round-12 slice 27: optional dark/light override applied at app root.
    private var preferredColorScheme: ColorScheme? {
        switch themeOverride {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

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
        .preferredColorScheme(preferredColorScheme)
        .onChange(of: scenePhase) { _, phase in
            // Round-22 slice T2.12: drain pending watch hydration taps
            // each time the iPhone foregrounds.
            if phase == .active {
                _ = WatchHydrationReconciler.drain(into: env.hydrationService)
            }
        }
        .task {
            // Round-12 slice 19: record this launch in the rolling history.
            ProcessLaunchHistoryStore.recordLaunch()
            // Round 11: auto-popup "What's new" the first time the app
            // launches with a commit SHA the user hasn't acknowledged. We
            // gate on `hasCompletedOnboarding` so the very first install
            // doesn't double up with the onboarding flow.
            guard hasCompletedOnboarding else { return }
            let current = BuildInfo.commitSHA
            if !current.isEmpty, current != "dev", current != lastSeenCommitSHA {
                showingWhatsNewAuto = true
            }
        }
        .sheet(
            isPresented: $showingWhatsNewAuto,
            onDismiss: {
                lastSeenCommitSHA = BuildInfo.commitSHA
                // Round-12 slice 18: persist the seen SHA into the rolling
                // history so DiagnosticsView can show the last few releases
                // the device acknowledged.
                WhatsNewHistoryStore.record(commitSHA: BuildInfo.commitSHA)
            },
            content: { WhatsNewSheet() }
        )
    }
}

private struct MainTabs: View {
    let env: AppEnvironment
    @State private var selection: AppTab = .today
    @State private var autoOpenNewTemplate = false

    var body: some View {
        TabView(selection: $selection) {
            TodayView(
                viewModel: TodayViewModel(
                    repository: env.routineRepository,
                    tripsRepository: env.tripsRepository,
                    skipStore: env.blockSkipStore,
                    snoozeStore: env.blockSnoozeStore,
                    focusScheduleStore: env.focusScheduleStore
                ),
                onCreateTemplate: {
                    autoOpenNewTemplate = true
                    selection = .templates
                }
            )
            .tag(AppTab.today)
            .tabItem {
                Label {
                    Text("tab.today", bundle: .main)
                } icon: {
                    Image(systemName: "sun.max")
                }
            }

            TemplateListView(
                viewModel: TemplateListViewModel(repository: env.routineRepository),
                repository: env.routineRepository,
                autoPresentNewTemplate: $autoOpenNewTemplate
            )
            .tag(AppTab.templates)
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
            .tag(AppTab.medication)
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
            .tag(AppTab.sleep)
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
            .tag(AppTab.hydration)
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
            .tag(AppTab.housekeeping)
            .tabItem {
                Label {
                    Text("tab.housekeeping", bundle: .main)
                } icon: {
                    Image(systemName: "checklist")
                }
            }

            BirthdaysView(
                viewModel: BirthdaysViewModel(
                    service: env.contactsService,
                    leadStore: env.birthdayLeadStore
                )
            )
            .tag(AppTab.birthdays)
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
                    itineraryStore: env.itineraryStore,
                    marineService: env.marineService,
                    currencyService: env.currencyService,
                    advisoryService: env.advisoryService
                )
            )
            .tag(AppTab.trips)
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
                ),
                focusScheduleStore: env.focusScheduleStore,
                diagnosticsActions: makeDiagnosticsActions(),
                routineRepository: env.routineRepository
            )
            .tag(AppTab.settings)
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

    private func makeDiagnosticsActions() -> DiagnosticsActions {
        DiagnosticsActionsFactory.make(env: env)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
