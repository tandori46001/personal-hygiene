import Foundation
import UserNotifications

/// Round-14 slice 17: grouping helper for `pending` IDs by category. Returns
/// `[Category: [identifier]]` so DiagnosticsView can render a disclosure-per-
/// category instead of a flat 50-row list.
public enum PendingNotificationsGroup {

    public enum Category: String, CaseIterable, Sendable {
        case routine
        case medicationFollowUp
        case hydration
        case milestones
        case housekeeping
        case other

        public var displayName: String {
            switch self {
            case .routine: "Routine"
            case .medicationFollowUp: "Medication follow-up"
            case .hydration: "Hydration"
            case .milestones: "Trip milestones"
            case .housekeeping: "Housekeeping"
            case .other: "Other"
            }
        }
    }

    public static func grouped(
        _ identifiers: [String]
    ) -> [(category: Category, identifiers: [String])] {
        var buckets: [Category: [String]] = [:]
        for id in identifiers {
            let cat: Category
            if id.hasPrefix(MedicationFollowUpFactory.identifierPrefix) {
                cat = .medicationFollowUp
            } else if id.hasPrefix(NotificationFactory.identifierPrefix) {
                cat = .routine
            } else if id.hasPrefix(HydrationNotificationFactory.identifierPrefix) {
                cat = .hydration
            } else if id.hasPrefix(TripMilestoneNotificationFactory.identifierPrefix) {
                cat = .milestones
            } else if id.hasPrefix(HousekeepingNotificationFactory.identifierPrefix) {
                cat = .housekeeping
            } else {
                cat = .other
            }
            buckets[cat, default: []].append(id)
        }
        return Category.allCases
            .compactMap { cat -> (category: Category, identifiers: [String])? in
                guard let ids = buckets[cat], !ids.isEmpty else { return nil }
                return (category: cat, identifiers: ids)
            }
    }
}
