import Foundation
@preconcurrency import UserNotifications

/// Builds the closure-bag that `DiagnosticsView` uses to read process-local
/// state without knowing about concrete service types. Factored out of
/// `ContentView` to keep that view's `makeDiagnosticsActions` body under
/// SwiftLint's function-body cap.
@MainActor
enum DiagnosticsActionsFactory {

    // MARK: - Make

    static func make(env: AppEnvironment) -> DiagnosticsActions {
        let observer = env.medicationObserver
        let tripsRepo = env.tripsRepository
        let docStore = env.tripDocumentStore

        return DiagnosticsActions(
            scheduleTestNotification: { await Self.scheduleTestNotification() },
            clearAllPending: {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            },
            injectSnoozeBadge: {
                Self.injectFirstBlockSnoozeBadge(
                    repository: env.routineRepository,
                    store: env.blockSnoozeStore
                )
            },
            resetDevStores: {
                Self.resetDevStores(
                    skipStore: env.blockSkipStore,
                    snoozeStore: env.blockSnoozeStore
                )
            },
            replayLastDelivered: { await Self.replayLastDelivered() },
            scheduleMedicationTest: { await Self.scheduleMedicationTest() },
            requestAuthorization: { await Self.requestAuthorization() },
            refreshTrace: { RefreshTraceLog.shared.newestFirst },
            scheduleDiff: { try await Self.scheduleDiff(env: env) },
            widgetReloadCount: { WidgetReloadCounter.shared.count },
            medicationObserverSnapshot: { Self.observerSnapshot(observer) },
            tripDocumentCount: { Self.tripDocCount(tripsRepo: tripsRepo) },
            tripDocumentByteFootprint: {
                Self.tripDocByteFootprint(tripsRepo: tripsRepo, docStore: docStore)
            },
            processUptimeSeconds: { ProcessLaunchTimer.uptimeSeconds() },
            exportSnapshot: {
                try await Self.exportSnapshot(
                    observer: observer,
                    tripsRepo: tripsRepo,
                    docStore: docStore
                )
            },
            pendingByCategory: { await Self.pendingByCategory() },
            tripDocumentDetails: {
                Self.tripDocDetails(tripsRepo: tripsRepo, docStore: docStore)
            },
            launchHistory: { ProcessLaunchHistoryStore.history() },
            whatsNewHistory: { WhatsNewHistoryStore.history() },
            snapshotHistory: { SnapshotHistoryStore.snapshots() },
            authTimeline: { NotificationAuthTimelineLog.entries() },
            networkCounts: { NetworkActivityCounter.shared.totals },
            pendingDetails: { await Self.pendingDetails() }
        )
    }

    static func pendingDetails() async -> [DiagnosticsSnapshot.PendingNotificationSummary] {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        return pending.map { req in
            let triggerDate = (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                ?? (req.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
            return DiagnosticsSnapshot.PendingNotificationSummary(
                identifier: req.identifier,
                triggerDate: triggerDate
            )
        }
    }

    static func pendingByCategory() async -> PendingNotificationsByCategory {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return PendingNotificationsByCategory.fromPending(pending)
    }

    static func tripDocDetails(
        tripsRepo: any TripsRepository,
        docStore: TripDocumentStore
    ) -> [(name: String, bytes: Int)] {
        guard let trips = try? tripsRepo.allTrips() else { return [] }
        var output: [(name: String, bytes: Int)] = []
        for trip in trips {
            for doc in trip.documents {
                let size = (try? docStore.bytes(for: doc).count) ?? 0
                output.append((name: doc.name, bytes: size))
            }
        }
        return output
    }

    // MARK: - Closure backers (factored out to keep `make` under SwiftLint's body cap)

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    static func scheduleDiff(env: AppEnvironment) async throws -> (pending: Int, expected: Int) {
        // Round-11 fix: compare like-with-like. The coordinator's
        // buildTodayNotifications() only emits routine + medication
        // follow-ups, so we filter pending requests by the same prefixes;
        // trip-milestone + hydration pending notifs no longer inflate Δ.
        let coordinator = env.makeNotificationCoordinator()
        let allPending = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()
        let routinePending = allPending.filter { req in
            req.identifier.hasPrefix(NotificationFactory.identifierPrefix)
                || req.identifier.hasPrefix(MedicationFollowUpFactory.identifierPrefix)
        }
        let expected = try await coordinator.buildTodayNotifications().count
        return (pending: routinePending.count, expected: expected)
    }

    static func observerSnapshot(_ observer: any MedicationObserving) -> (available: Bool, identifiers: [String]) {
        let identifiers = (observer as? MedicationObserverService)?.registeredIdentifiers ?? []
        return (available: observer.isAvailable, identifiers: identifiers)
    }

    static func tripDocCount(tripsRepo: any TripsRepository) -> Int {
        (try? tripsRepo.allTrips())?.reduce(0) { $0 + $1.documents.count } ?? 0
    }

    static func tripDocByteFootprint(tripsRepo: any TripsRepository, docStore: TripDocumentStore) -> Int? {
        guard let trips = try? tripsRepo.allTrips() else { return nil }
        var total = 0
        for trip in trips {
            for doc in trip.documents {
                guard let bytes = try? docStore.bytes(for: doc) else { return nil }
                total += bytes.count
            }
        }
        return total
    }

    static func exportSnapshot(
        observer: any MedicationObserving,
        tripsRepo: any TripsRepository,
        docStore: TripDocumentStore
    ) async throws -> URL {
        let snap = observerSnapshot(observer)
        let docCount = tripDocCount(tripsRepo: tripsRepo)
        let docBytes = await computeDocFootprint(tripsRepo: tripsRepo, docStore: docStore)
        let snapshot = await DiagnosticsSnapshot.capture(
            widgetReloadCount: WidgetReloadCounter.shared.count,
            observerAvailable: snap.available,
            observerIdentifiers: snap.identifiers,
            tripDocumentCount: docCount,
            tripDocumentByteFootprint: docBytes
        )
        // Round-13 slice 15: persist to local history alongside the file.
        SnapshotHistoryStore.record(snapshot)
        return try snapshot.writeToTemporaryFile()
    }

    @MainActor
    private static func computeDocFootprint(
        tripsRepo: any TripsRepository,
        docStore: TripDocumentStore
    ) async -> Int? {
        guard let trips = try? tripsRepo.allTrips() else { return nil }
        var total = 0
        for trip in trips {
            for doc in trip.documents {
                guard let bytes = try? docStore.bytes(for: doc) else { return nil }
                total += bytes.count
            }
        }
        return total
    }

    // MARK: - Helpers

    static func scheduleTestNotification() async {
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

    static func injectFirstBlockSnoozeBadge(
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

    static func resetDevStores(
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

    static func replayLastDelivered() async -> String? {
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

    static func scheduleMedicationTest() async {
        // Primary medication notification at +60s (real category so the
        // mark-done/snooze actions show up). Follow-up at +90s mirrors the
        // M3.2 "missed-dose" path the MedicationFollowUpFactory produces in
        // production (default offset is 30 min; we shrink it to 30s here so
        // QA can verify the wiring inline).
        let center = UNUserNotificationCenter.current()
        let blockID = UUID()
        let dayKey = "test"
        try? await center.add(makePrimaryMedRequest(blockID: blockID, dayKey: dayKey))
        try? await center.add(makeFollowUpMedRequest(blockID: blockID, dayKey: dayKey))
    }

    private static func makePrimaryMedRequest(blockID: UUID, dayKey: String) -> UNNotificationRequest {
        let primary = UNMutableNotificationContent()
        primary.title = String(localized: "settings.diagnostics.devTools.medicationTest.primary.title")
        primary.body = String(localized: "settings.diagnostics.devTools.medicationTest.primary.body")
        primary.sound = .default
        primary.categoryIdentifier = NotificationCategoryID.routineBlock
        primary.threadIdentifier = NotificationThreadID.routine
        let id = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).\(dayKey)"
        return UNNotificationRequest(
            identifier: id,
            content: primary,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        )
    }

    private static func makeFollowUpMedRequest(blockID: UUID, dayKey: String) -> UNNotificationRequest {
        let followUp = UNMutableNotificationContent()
        followUp.title = String(localized: "settings.diagnostics.devTools.medicationTest.followup.title")
        followUp.body = String(localized: "settings.diagnostics.devTools.medicationTest.followup.body")
        followUp.sound = .default
        followUp.threadIdentifier = NotificationThreadID.routine
        let id = MedicationFollowUpFactory.identifier(blockID: blockID, dayKey: dayKey)
        return UNNotificationRequest(
            identifier: id,
            content: followUp,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 90, repeats: false)
        )
    }
}
