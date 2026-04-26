import Foundation

/// Pure value type returned by `ItineraryGenerator`. Not persisted in
/// SwiftData — itineraries are regenerated on demand and live in-memory only.
public struct TripItinerary: Equatable, Sendable {

    public struct Day: Equatable, Sendable {
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
