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
        } catch {
            lastError = error.localizedDescription
        }
    }
}
