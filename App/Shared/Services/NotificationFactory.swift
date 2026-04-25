import Foundation

/// A planned notification computed from a `Block`. Pure value type — no
/// dependency on `UNUserNotificationCenter` so it can be unit-tested freely.
public struct ScheduledNotification: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let body: String?
    public let triggerDate: Date
    public let isCritical: Bool

    public init(
        identifier: String,
        title: String,
        body: String? = nil,
        triggerDate: Date,
        isCritical: Bool
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.triggerDate = triggerDate
        self.isCritical = isCritical
    }
}

/// Maps `Block`s to `ScheduledNotification`s for a given calendar day.
///
/// Notifications fire `block.notificationLeadMinutes` before the block start.
/// Blocks whose computed trigger lands before midnight (negative offset) are skipped.
public enum NotificationFactory {

    /// Identifier prefix for any notification this app schedules.
    public static let identifierPrefix = "personal-hygiene.block."

    public static func notifications(
        for blocks: [Block],
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ScheduledNotification] {
        let dayStart = calendar.startOfDay(for: date)
        let dayKey = isoDayKey(for: date, calendar: calendar)

        return blocks.compactMap { block -> ScheduledNotification? in
            scheduledNotification(
                for: block,
                effectiveLeadMinutes: block.notificationLeadMinutes,
                dayStart: dayStart,
                dayKey: dayKey,
                calendar: calendar
            )
        }
    }

    /// Async variant that adds travel-time on top of each block's static lead
    /// minutes when the block has a `location` and an `origin` + service are
    /// supplied. If the service throws, the static lead is used as a safe
    /// fallback so the user still gets a notification.
    @MainActor
    public static func notifications(
        for blocks: [Block],
        on date: Date,
        origin: BlockLocation?,
        travelTimeService: (any TravelTimeService)?,
        travelMode: TravelMode = .automobile,
        calendar: Calendar = .autoupdatingCurrent
    ) async -> [ScheduledNotification] {
        let dayStart = calendar.startOfDay(for: date)
        let dayKey = isoDayKey(for: date, calendar: calendar)

        var result: [ScheduledNotification] = []
        result.reserveCapacity(blocks.count)

        for block in blocks {
            let lead = await effectiveLeadMinutes(
                for: block,
                origin: origin,
                travelTimeService: travelTimeService,
                travelMode: travelMode
            )
            if let notification = scheduledNotification(
                for: block,
                effectiveLeadMinutes: lead,
                dayStart: dayStart,
                dayKey: dayKey,
                calendar: calendar
            ) {
                result.append(notification)
            }
        }
        return result
    }

    @MainActor
    private static func effectiveLeadMinutes(
        for block: Block,
        origin: BlockLocation?,
        travelTimeService: (any TravelTimeService)?,
        travelMode: TravelMode
    ) async -> Int {
        guard
            let destination = block.location,
            let origin,
            let travelTimeService
        else {
            return block.notificationLeadMinutes
        }
        do {
            let seconds = try await travelTimeService.estimatedTravelTime(
                from: origin,
                to: destination,
                mode: travelMode
            )
            let travelMinutes = Int((seconds / 60).rounded(.up))
            return block.notificationLeadMinutes + max(0, travelMinutes)
        } catch {
            return block.notificationLeadMinutes
        }
    }

    private static func scheduledNotification(
        for block: Block,
        effectiveLeadMinutes: Int,
        dayStart: Date,
        dayKey: String,
        calendar: Calendar
    ) -> ScheduledNotification? {
        let triggerMinutes = block.startMinutesFromMidnight - effectiveLeadMinutes
        guard triggerMinutes >= 0 else { return nil }
        guard let trigger = calendar.date(byAdding: .minute, value: triggerMinutes, to: dayStart) else {
            return nil
        }
        return ScheduledNotification(
            identifier: "\(identifierPrefix)\(block.id.uuidString).\(dayKey)",
            title: block.title,
            body: block.notes,
            triggerDate: trigger,
            isCritical: block.category == .medication
        )
    }

    private static func isoDayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
