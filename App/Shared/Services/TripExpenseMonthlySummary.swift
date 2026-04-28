import Foundation

/// Round-18 slice 14: groups `[TripExpense]` by `(year, month, currency)` so
/// the trip detail view can render a "Monthly summary" disclosure with
/// per-month per-currency totals. Pure helper. Returns the buckets sorted
/// newest-first.
public enum TripExpenseMonthlySummary {

    public struct Bucket: Equatable, Sendable, Identifiable {
        public let id: String  // "yyyy-MM:CCY"
        public let year: Int
        public let month: Int
        public let currencyCode: String
        public let total: Double
        public let count: Int

        public init(
            id: String,
            year: Int,
            month: Int,
            currencyCode: String,
            total: Double,
            count: Int
        ) {
            self.id = id
            self.year = year
            self.month = month
            self.currencyCode = currencyCode
            self.total = total
            self.count = count
        }
    }

    public static func buckets(
        from expenses: [TripExpense],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Bucket] {
        struct Key: Hashable {
            let year: Int
            let month: Int
            let currency: String
        }
        var totals: [Key: (Double, Int)] = [:]
        for expense in expenses {
            let comps = calendar.dateComponents([.year, .month], from: expense.occurredAt)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = Key(year: year, month: month, currency: expense.currencyCode)
            let prior = totals[key] ?? (0, 0)
            totals[key] = (prior.0 + expense.amount, prior.1 + 1)
        }
        let buckets: [Bucket] = totals.map { key, value in
            let id = String(format: "%04d-%02d:%@", key.year, key.month, key.currency)
            return Bucket(
                id: id,
                year: key.year,
                month: key.month,
                currencyCode: key.currency,
                total: value.0,
                count: value.1
            )
        }
        return buckets.sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year > rhs.year }
            if lhs.month != rhs.month { return lhs.month > rhs.month }
            return lhs.currencyCode < rhs.currencyCode
        }
    }

    /// Helper for the UI: "yyyy-MM" formatted display string.
    public static func formattedMonth(year: Int, month: Int) -> String {
        String(format: "%04d-%02d", year, month)
    }
}
