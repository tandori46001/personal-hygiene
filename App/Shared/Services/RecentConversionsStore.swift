import Foundation

/// Persists the last N currency conversions so `CurrencyView` can show recent
/// activity without forcing the user to retype amounts. Stored as a JSON
/// array under a single UserDefaults key so the round-trip is transparent.
public enum RecentConversionsStore {

    public static let key = "currency.recentConversions"
    public static let capacity = 5

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public let id: UUID
        public let from: String
        public let to: String
        public let amount: Double
        public let amountConverted: Double
        public let rate: Double
        public let recordedAt: Date

        public init(
            id: UUID = UUID(),
            from: String,
            to: String,
            amount: Double,
            amountConverted: Double,
            rate: Double,
            recordedAt: Date = Date()
        ) {
            self.id = id
            self.from = from
            self.to = to
            self.amount = amount
            self.amountConverted = amountConverted
            self.rate = rate
            self.recordedAt = recordedAt
        }
    }

    public static func recent(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func record(
        _ conversion: CurrencyConversion,
        amount: Double,
        in defaults: UserDefaults = .standard
    ) {
        let entry = Entry(
            from: conversion.from,
            to: conversion.to,
            amount: amount,
            amountConverted: conversion.amountConverted,
            rate: conversion.rate
        )
        var current = recent(defaults: defaults)
        // De-dupe identical (from, to, amount) — replace older copy with the
        // fresh timestamp so users see the latest result at top.
        current.removeAll { $0.from == entry.from && $0.to == entry.to && $0.amount == entry.amount }
        current.insert(entry, at: 0)
        if current.count > capacity { current = Array(current.prefix(capacity)) }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
