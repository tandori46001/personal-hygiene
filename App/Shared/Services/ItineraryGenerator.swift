import Foundation

@MainActor
public protocol ItineraryGenerator {
    func generate(for trip: Trip) async throws -> TripItinerary
}

public enum ItineraryGeneratorError: Error, LocalizedError {
    case modelUnavailable
    case malformedResponse

    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            "On-device model is not available on this device."
        case .malformedResponse:
            "The model returned an unexpected response."
        }
    }
}

/// Deterministic generator used in unit tests, previews, and as a fallback when
/// `FoundationModelsItineraryGenerator` reports the model is not available.
@MainActor
public struct StubItineraryGenerator: ItineraryGenerator {

    public init() {}

    public func generate(for trip: Trip) async throws -> TripItinerary {
        let totalDays = max(
            1,
            Calendar(identifier: .gregorian)
                .dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 1
        )
        let days = (0..<totalDays).map { offset in
            TripItinerary.Day(
                title: "Day \(offset + 1)",
                activities: [
                    "Explore \(trip.destinationName)",
                    "Lunch at a local spot",
                    "Evening walk",
                ]
            )
        }
        return TripItinerary(
            summary: "A \(totalDays)-day plan for \(trip.destinationName).",
            days: days
        )
    }
}
