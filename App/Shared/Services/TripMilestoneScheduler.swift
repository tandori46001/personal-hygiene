import Foundation

/// Refreshes pending milestone notifications for every active trip in the
/// repository. Cancels milestone-prefixed notifications first so the refresh is
/// idempotent and won't ever leave stale reminders behind.
@MainActor
public final class TripMilestoneScheduler {

    private let repository: any TripsRepository
    private let service: any NotificationService
    private let calendar: Calendar

    public init(
        repository: any TripsRepository,
        service: any NotificationService,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.service = service
        self.calendar = calendar
    }

    public func refresh(now: Date = Date()) async throws {
        let trips = try repository.allTrips()
        var all: [ScheduledNotification] = []
        for trip in trips {
            all.append(
                contentsOf: TripMilestoneNotificationFactory.notifications(
                    for: trip,
                    now: now,
                    calendar: calendar
                )
            )
        }
        try await service.scheduleAll(
            all,
            cancellingPrefix: TripMilestoneNotificationFactory.identifierPrefix
        )
    }
}
