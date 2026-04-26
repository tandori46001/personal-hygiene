import Foundation

/// Orchestrates building notifications from the active templates and
/// handing them off to the platform `NotificationService`.
@MainActor
public final class NotificationCoordinator {

    private let repository: any RoutineRepository
    private let service: any NotificationService
    private let travelTimeService: (any TravelTimeService)?
    private let homeLocation: BlockLocation?
    private let travelMode: TravelMode
    private let calendar: Calendar

    public init(
        repository: any RoutineRepository,
        service: any NotificationService,
        travelTimeService: (any TravelTimeService)? = nil,
        homeLocation: BlockLocation? = nil,
        travelMode: TravelMode = .automobile,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.service = service
        self.travelTimeService = travelTimeService
        self.homeLocation = homeLocation
        self.travelMode = travelMode
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

        let blocks = template.sortedBlocks
        let raw: [ScheduledNotification]
        if travelTimeService != nil, homeLocation != nil {
            raw = await NotificationFactory.notifications(
                for: blocks,
                on: now,
                origin: homeLocation,
                travelTimeService: travelTimeService,
                travelMode: travelMode,
                calendar: calendar
            )
        } else {
            raw = NotificationFactory.notifications(
                for: blocks,
                on: now,
                calendar: calendar
            )
        }
        let focusWindows = DeepFocusFilter.focusWindows(for: blocks, on: now, calendar: calendar)
        let filtered = DeepFocusFilter.suppressing(raw, focusWindows: focusWindows)
        try await service.scheduleAll(filtered)
    }
}
