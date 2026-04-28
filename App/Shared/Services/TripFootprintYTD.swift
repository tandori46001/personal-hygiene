import Foundation

/// Round-25 slice T5.32: year-to-date carbon footprint summary across all
/// trips that *started* in the current calendar year. Pure helper.
public enum TripFootprintYTD {

    public struct Summary: Equatable, Sendable {
        public let yearStart: Date
        public let totalKgCO2: Double
        public let tripCount: Int
    }

    public static func summarize(
        contributions: [(startDate: Date, kgCO2: Double)],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Summary {
        let year = calendar.component(.year, from: now)
        let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1))
            ?? now
        let inYear = contributions.filter { $0.startDate >= yearStart && $0.startDate <= now }
        let total = inYear.map(\.kgCO2).reduce(0, +)
        return Summary(
            yearStart: yearStart,
            totalKgCO2: total,
            tripCount: inYear.count
        )
    }
}
