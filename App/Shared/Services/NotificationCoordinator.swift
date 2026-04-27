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
        let built = try await buildTodayNotifications(now: now)
        try await service.scheduleAll(built)
    }

    /// Pure-build pipeline for today's routine + follow-up notifications. The
    /// returned array is what `refreshForToday` would have scheduled. Reused
    /// by `rescheduleToday(shiftedByMinutes:)` so the user can offset every
    /// notification by ±N minutes after a late wake-up / jet-lag without
    /// touching the block start times in storage.
    public func buildTodayNotifications(now: Date = Date()) async throws -> [ScheduledNotification] {
        let todayType = TodayViewModel.dayType(for: now, in: calendar)
        guard let template = try repository.activeTemplate(for: todayType) else {
            await service.cancelAll()
            return []
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
        return filtered + Self.medicationFollowUps(
            primaries: filtered,
            blocks: blocks,
            now: now,
            calendar: calendar
        )
    }

    /// One-shot "shift today's notifications by ±N minutes" for jet-lag /
    /// late-wake recovery. Builds today's nominal schedule, applies the shift
    /// in-memory, drops anything that lands in the past, and re-schedules the
    /// result. Block start times in storage are not modified.
    public func rescheduleToday(shiftedByMinutes shiftMinutes: Int, now: Date = Date()) async throws {
        let nominal = try await buildTodayNotifications(now: now)
        let shifted = Self.shifted(nominal, byMinutes: shiftMinutes, dropPastBefore: now)
        try await service.scheduleAll(shifted)
    }

    /// Pure shift-and-filter for `ScheduledNotification`s. Exposed for tests.
    static func shifted(
        _ notifications: [ScheduledNotification],
        byMinutes shiftMinutes: Int,
        dropPastBefore now: Date
    ) -> [ScheduledNotification] {
        let interval = TimeInterval(shiftMinutes * 60)
        return notifications.compactMap { notif -> ScheduledNotification? in
            let newDate = notif.triggerDate.addingTimeInterval(interval)
            guard newDate > now else { return nil }
            return ScheduledNotification(
                identifier: notif.identifier,
                title: notif.title,
                body: notif.body,
                triggerDate: newDate,
                isCritical: notif.isCritical,
                threadIdentifier: notif.threadIdentifier,
                categoryIdentifier: notif.categoryIdentifier
            )
        }
    }

    /// PRD M3.2 fallback: every primary medication notification gains a +30
    /// min follow-up so the user gets re-notified if they ignored the first
    /// alert. Pure side-effect-free helper so tests can verify the pairing.
    /// Matches primaries → blocks via `BlockNotificationIdentifier.parseAny`
    /// (routine kind) so the pairing breaks at compile/parse time if the
    /// identifier shape ever changes — not silently like the old substring
    /// match did.
    static func medicationFollowUps(
        primaries: [ScheduledNotification],
        blocks: [Block],
        now: Date,
        calendar: Calendar
    ) -> [ScheduledNotification] {
        let medicationBlocks = Dictionary(
            uniqueKeysWithValues: blocks
                .filter { $0.medicationConceptIdentifier != nil }
                .map { ($0.id, $0) }
        )
        return primaries.compactMap { primary -> ScheduledNotification? in
            guard case let .routine(blockID, dayKey) = BlockNotificationIdentifier.parseAny(primary.identifier),
                  let block = medicationBlocks[blockID]
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
