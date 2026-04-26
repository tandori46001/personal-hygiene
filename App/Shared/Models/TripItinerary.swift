import Foundation

/// Pure value type returned by `ItineraryGenerator`. Persisted to disk by
/// `ItineraryStore` (one JSON file per trip) so the last generation survives
/// app restarts; not stored in SwiftData / not synced via CloudKit.
public struct TripItinerary: Equatable, Sendable, Codable {

    public struct Day: Equatable, Sendable, Codable {
        public let title: String
        public let activities: [String]

        public init(title: String, activities: [String]) {
            self.title = title
            self.activities = activities
        }
    }

    public let summary: String
    public let days: [Day]

    public init(summary: String, days: [Day]) {
        self.summary = summary
        self.days = days
    }
}
