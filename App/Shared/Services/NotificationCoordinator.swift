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
    private let skipStore: (any BlockSkipStore)?
    private let focusScheduleStore: (any FocusScheduleStore)?
    private let calendar: Calendar

    public init(
        repository: any RoutineRepository,
        service: any NotificationService,
        travelTimeService: (any TravelTimeService)? = nil,
        homeLocation: BlockLocation? = nil,
        travelMode: TravelMode = .automobile,
        skipStore: (any BlockSkipStore)? = nil,
        focusScheduleStore: (any FocusScheduleStore)? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.service = service
        self.travelTimeService = travelTimeService
        self.homeLocation = homeLocation
        self.travelMode = travelMode
        self.skipStore = skipStore
        self.focusScheduleStore = focusScheduleStore
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

        skipStore?.purgeStale(before: now, calendar: calendar, keepLastDays: 7)
        let blocks = template.sortedBlocks.filter { block in
            skipStore?.isSkipped(blockID: block.id, on: now, calendar: calendar) != true
        }
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
        let scheduled = focusScheduleStore?.windows() ?? []
        let focusWindows = DeepFocusFilter.focusWindows(
            for: blocks,
            on: now,
            scheduledWindows: scheduled,
            calendar: calendar
        )
        let filtered = DeepFocusFilter.suppressing(raw, focusWindows: focusWindows)
        let withFollowUps = filtered + Self.medicationFollowUps(
            primaries: filtered,
            blocks: blocks,
            now: now,
            calendar: calendar
        )
        try await service.scheduleAll(withFollowUps)
    }

    /// PRD M3.2 fallback: every primary medication notification gains a +30
    /// min follow-up so the user gets re-notified if they ignored the first
    /// alert. Pure side-effect-free helper so tests can verify the pairing.
    static func medicationFollowUps(
        primaries: [ScheduledNotification],
        blocks: [Block],
        now: Date,
        calendar: Calendar
    ) -> [ScheduledNotification] {
        let medicationBlocks = blocks.filter { $0.medicationConceptIdentifier != nil }
        let dayKey = String(
            format: "%04d-%02d-%02d",
            calendar.component(.year, from: now),
            calendar.component(.month, from: now),
            calendar.component(.day, from: now)
        )
        return primaries.compactMap { primary -> ScheduledNotification? in
            // Match the primary to its source block by identifier suffix.
            guard let block = medicationBlocks.first(where: { primary.identifier.contains($0.id.uuidString) })
            else { return nil }
            return MedicationFollowUpFactory.followUp(
                for: primary,
                block: block,
                dayKey: dayKey,
                calendar: calendar
            )
        }
    }
}
