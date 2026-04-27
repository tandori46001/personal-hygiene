import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    private let service: any NotificationService
    private let coordinator: NotificationCoordinator

    var status: NotificationAuthorizationStatus = .notDetermined
    var lastError: String?
    var lastRefreshAt: Date?
    /// Set to the count of notifications scheduled by the most recent
    /// `rescheduleToday` call so the view can surface a "N reschedulé" toast.
    /// Cleared after the user dismisses it.
    var lastRescheduleCount: Int?

    init(service: any NotificationService, coordinator: NotificationCoordinator) {
        self.service = service
        self.coordinator = coordinator
    }

    func reloadStatus() async {
        status = await service.authorizationStatus()
    }

    func requestPermission() async {
        do {
            _ = try await service.requestAuthorization(criticalAlerts: false)
            await reloadStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshNotifications() async {
        do {
            try await coordinator.refreshForToday()
            lastRefreshAt = Date()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func rescheduleToday(shiftedByMinutes shiftMinutes: Int) async {
        do {
            try await coordinator.rescheduleToday(shiftedByMinutes: shiftMinutes)
            lastRefreshAt = Date()
            // Re-read the trace log so the toast shows the count we just
            // shipped instead of an opaque "done" — the trace records the
            // exact value `scheduleAll` was given.
            lastRescheduleCount = RefreshTraceLog.shared.entries.last?.scheduledCount ?? 0
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearLastRescheduleCount() {
        lastRescheduleCount = nil
    }
}
