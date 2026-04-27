import Foundation

/// Round-13 slice 10: free-form trip expense entry. Value type stored as a
/// JSON-encoded array on `Trip.expensesJSON`. Currency is captured per
/// expense so we can convert to a primary currency at display time without
/// rewriting historical entries.
public struct TripExpense: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var label: String
    public var amount: Double
    public var currencyCode: String
    public var occurredAt: Date

    public init(
        id: UUID = UUID(),
        label: String,
        amount: Double,
        currencyCode: String,
        occurredAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.currencyCode = currencyCode.uppercased()
        self.occurredAt = occurredAt
    }
}
