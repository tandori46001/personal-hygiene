import Foundation

/// Round-12 slice 3: persists the most-recent currency conversion so
/// `CurrencyView` can restore the rate on next visit without forcing a fresh
/// network round-trip. Distinct from `RecentConversionsStore` (last 5
/// dedup'd entries) — this one is a single-slot "last result + rate" so the
/// rate panel keeps showing data after navigating away and back.
public enum LastConversionStore {

    public static let key = "currency.lastConversion"

    public struct Entry: Codable, Equatable, Sendable {
        public let from: String
        public let to: String
        public let amount: Double
        public let amountConverted: Double
        public let rate: Double
        public let recordedAt: Date

        public init(
            from: String,
            to: String,
            amount: Double,
            amountConverted: Double,
            rate: Double,
            recordedAt: Date = Date()
        ) {
            self.from = from
            self.to = to
            self.amount = amount
            self.amountConverted = amountConverted
            self.rate = rate
            self.recordedAt = recordedAt
        }
    }

    public static func load(defaults: UserDefaults = .standard) -> Entry? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Entry.self, from: data)
    }

    public static func save(
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
        if let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
