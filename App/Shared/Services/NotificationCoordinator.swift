import Foundation

/// Orchestrates building notifications from the active templates and
/// handing them off to the platform `NotificationService`.
@MainActor
public final class NotificationCoordinator {

    private let repository: any RoutineRepository
    private let service: any NotificationService
    private let calendar: Calendar

    public init(
        repository: any RoutineRepository,
        service: any NotificationService,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.service = service
        self.calendar = calendar
    }

    /// Schedule notifications for today's active template based on the user's
    /// current day-type. Cancels any previously scheduled `personal-hygiene` notifications first.
    public func refreshForToday(_ now: Date = Date()) async throws {
        let todayType = TodayViewModel.dayType(for: now, in: calendar)
        guard let template = try repository.activeTemplate(for: todayType) else {
            await service.cancelAll()
            return
        }

        let notifications = NotificationFactory.notifications(
            for: template.sortedBlocks,
            on: now,
            calendar: calendar
        )
        try await service.scheduleAll(notifications)
    }
}
