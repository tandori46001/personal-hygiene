import Foundation
import UserNotifications

/// Round-12 slice 1: per-category breakdown of pending notification requests.
/// Round-11 collapsed everything into a single `pending` count and filtered by
/// routine/medication-followup prefixes only — that hid drift in milestone +
/// hydration scheduling. This type splits the count by prefix so DiagnosticsView
/// can surface non-zero deltas for any category, not just routine.
public struct PendingNotificationsByCategory: Equatable, Sendable {
    public let routine: Int
    public let medicationFollowUp: Int
    public let hydration: Int
    public let milestones: Int
    public let housekeeping: Int
    public let other: Int

    public var total: Int {
        routine + medicationFollowUp + hydration + milestones + housekeeping + other
    }

    public init(
        routine: Int,
        medicationFollowUp: Int,
        hydration: Int,
        milestones: Int,
        housekeeping: Int,
        other: Int
    ) {
        self.routine = routine
        self.medicationFollowUp = medicationFollowUp
        self.hydration = hydration
        self.milestones = milestones
        self.housekeeping = housekeeping
        self.other = other
    }

    public static func classify(_ identifiers: [String]) -> Self {
        var routine = 0
        var medFu = 0
        var hyd = 0
        var ms = 0
        var hk = 0
        var other = 0
        for id in identifiers {
            if id.hasPrefix(MedicationFollowUpFactory.identifierPrefix) {
                medFu += 1
            } else if id.hasPrefix(NotificationFactory.identifierPrefix) {
                routine += 1
            } else if id.hasPrefix(HydrationNotificationFactory.identifierPrefix) {
                hyd += 1
            } else if id.hasPrefix(TripMilestoneNotificationFactory.identifierPrefix) {
                ms += 1
            } else if id.hasPrefix(HousekeepingNotificationFactory.identifierPrefix) {
                hk += 1
            } else {
                other += 1
            }
        }
        return Self(
            routine: routine,
            medicationFollowUp: medFu,
            hydration: hyd,
            milestones: ms,
            housekeeping: hk,
            other: other
        )
    }

    public static func fromPending(_ requests: [UNNotificationRequest]) -> Self {
        classify(requests.map { $0.identifier })
    }
}
