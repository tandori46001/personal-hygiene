import SwiftData
import SwiftUI
import UserNotifications

enum AppTab: Hashable {
    case today, templates, medication, sleep, hydration, housekeeping, birthdays, trips, settings
}

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
                diagnosticsActions: makeDiagnosticsActions()
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
        let routineRepo = env.routineRepository
        let snoozeStore = env.blockSnoozeStore
        let skipStore = env.blockSkipStore
        return DiagnosticsActions(
            scheduleTestNotification: {
                await Self.scheduleTestNotification()
            },
            clearAllPending: {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            },
            injectSnoozeBadge: {
                Self.injectFirstBlockSnoozeBadge(repository: routineRepo, store: snoozeStore)
            },
            resetDevStores: {
                Self.resetDevStores(skipStore: skipStore, snoozeStore: snoozeStore)
            },
            replayLastDelivered: {
                await Self.replayLastDelivered()
            },
            scheduleMedicationTest: {
                await Self.scheduleMedicationTest()
            },
            requestAuthorization: {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
            }
        )
    }

    @MainActor
    private static func scheduleTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "settings.diagnostics.devTools.testNotif.title")
        content.body = String(localized: "settings.diagnostics.devTools.testNotif.body")
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryID.routineBlock
        content.threadIdentifier = NotificationThreadID.routine
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        let identifier = "\(NotificationFactory.identifierPrefix)\(UUID().uuidString).test"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    @MainActor
    private static func injectFirstBlockSnoozeBadge(
        repository: any RoutineRepository,
        store: any BlockSnoozeStore
    ) -> String? {
        let cal = Calendar.autoupdatingCurrent
        let dayType = TodayViewModel.dayType(for: Date(), in: cal)
        guard let template = try? repository.activeTemplate(for: dayType),
              let block = template.sortedBlocks.first
        else { return nil }
        let dayKey = String(
            format: "%04d-%02d-%02d",
            cal.component(.year, from: Date()),
            cal.component(.month, from: Date()),
            cal.component(.day, from: Date())
        )
        store.markSnoozed(blockID: block.id, dayKey: dayKey)
        return block.title
    }

    @MainActor
    private static func resetDevStores(
        skipStore: any BlockSkipStore,
        snoozeStore: any BlockSnoozeStore
    ) {
        // `removeAll()` wipes every entry, including today's. Older code used
        // `purgeStale(keepLastDays: 0)` which kept today (cutoff `>=` today),
        // so a snooze inserted earlier the same day would survive a reset.
        skipStore.removeAll()
        snoozeStore.removeAll()
        SnoozeDurationStore.set(SnoozeDurationStore.defaultMinutes, in: .standard)
    }

    @MainActor
    private static func replayLastDelivered() async -> String? {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        let mostRecent = delivered.max(by: { $0.date < $1.date })
        guard let original = mostRecent else { return nil }

        let content = UNMutableNotificationContent()
        content.title = original.request.content.title
        content.body = original.request.content.body
        content.sound = original.request.content.sound
        content.categoryIdentifier = original.request.content.categoryIdentifier
        content.threadIdentifier = original.request.content.threadIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "\(original.request.identifier).replay.\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
        return original.request.content.title
    }

    @MainActor
    private static func scheduleMedicationTest() async {
        // Primary medication notification at +60s (real category so the
        // mark-done/snooze actions show up). Follow-up at +90s mirrors the
        // M3.2 "missed-dose" path the MedicationFollowUpFactory produces in
        // production (default offset is 30 min; we shrink it to 30s here so
        // QA can verify the wiring inline).
        let center = UNUserNotificationCenter.current()
        let blockID = UUID()
        let dayKey = "test"

        let primary = UNMutableNotificationContent()
        primary.title = String(localized: "settings.diagnostics.devTools.medicationTest.primary.title")
        primary.body = String(localized: "settings.diagnostics.devTools.medicationTest.primary.body")
        primary.sound = .default
        primary.categoryIdentifier = NotificationCategoryID.routineBlock
        primary.threadIdentifier = NotificationThreadID.routine
        let primaryID = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).\(dayKey)"
        let primaryRequest = UNNotificationRequest(
            identifier: primaryID,
            content: primary,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        )

        let followUp = UNMutableNotificationContent()
        followUp.title = String(localized: "settings.diagnostics.devTools.medicationTest.followup.title")
        followUp.body = String(localized: "settings.diagnostics.devTools.medicationTest.followup.body")
        followUp.sound = .default
        followUp.threadIdentifier = NotificationThreadID.routine
        let followUpID = "\(MedicationFollowUpFactory.identifierPrefix)\(blockID.uuidString).\(dayKey)"
        let followUpRequest = UNNotificationRequest(
            identifier: followUpID,
            content: followUp,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 90, repeats: false)
        )

        try? await center.add(primaryRequest)
        try? await center.add(followUpRequest)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
