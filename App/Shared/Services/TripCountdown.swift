import Foundation

/// Round-25 slice T5.31: pure helper that returns the days-until-next-trip
/// for the Today header chip. Renders nothing when no upcoming trip is
/// scheduled or when the trip has already started.
public enum TripCountdown {

    public struct Summary: Equatable, Sendable {
        public let tripName: String
        public let daysUntil: Int
    }

    public static func nextSummary(
        trips: [Trip],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Summary? {
        let today = calendar.startOfDay(for: now)
        let upcoming = trips
            .filter { calendar.startOfDay(for: $0.startDate) > today }
            .min { $0.startDate < $1.startDate }
        guard let trip = upcoming else { return nil }
        let target = calendar.startOfDay(for: trip.startDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        return Summary(tripName: trip.name, daysUntil: max(0, days))
    }
}
