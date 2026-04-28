import Foundation

/// Round-25 slice T5.33 + T5.34: pure helper that compares a trip's
/// expense total against a budget figure. Caller passes both; the helper
/// only does math + classification.
public enum TripBudgetVsActual {

    public struct Summary: Equatable, Sendable {
        public let budget: Double
        public let actual: Double
        public let currencyCode: String
        public var delta: Double { actual - budget }
        public var fraction: Double {
            guard budget > 0 else { return actual > 0 ? 1 : 0 }
            return actual / budget
        }
    }

    public enum Status: Equatable, Sendable {
        case underBudget
        case onBudget
        case overBudget
    }

    public static func summarize(
        budget: Double,
        expenses: [TripExpense],
        currencyCode: String
    ) -> Summary {
        let actual = expenses
            .filter { $0.currencyCode == currencyCode.uppercased() }
            .map(\.amount)
            .reduce(0, +)
        return Summary(budget: budget, actual: actual, currencyCode: currencyCode.uppercased())
    }

    public static func status(for summary: Summary) -> Status {
        switch summary.fraction {
        case ..<0.95: return .underBudget
        case 0.95...1.05: return .onBudget
        default: return .overBudget
        }
    }
}
