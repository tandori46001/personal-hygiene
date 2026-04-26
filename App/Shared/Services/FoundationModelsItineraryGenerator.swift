import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// On-device itinerary generator using Apple Intelligence Foundation Models.
/// Falls back to throwing `ItineraryGeneratorError.modelUnavailable` when the
/// device hasn't downloaded a supported model.
@available(iOS 26.0, *)
@MainActor
public struct FoundationModelsItineraryGenerator: ItineraryGenerator {

    public init() {}

    public func generate(for trip: Trip) async throws -> TripItinerary {
        guard SystemLanguageModel.default.availability == .available else {
            throw ItineraryGeneratorError.modelUnavailable
        }

        let prompt = """
            Plan an itinerary for a trip to \(trip.destinationName) from \
            \(formattedDate(trip.startDate)) to \(formattedDate(trip.endDate)). \
            Suggest 3-5 activities per day, balancing sights, food, and rest. \
            Reply concisely.
            """

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: prompt,
            generating: GeneratedItinerary.self
        )
        return response.content.toDomain()
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedItinerary {

    @Guide(description: "One-sentence summary of the trip plan.")
    let summary: String

    @Guide(description: "One entry per day of the trip. Keep order chronological.")
    let days: [GeneratedDay]

    func toDomain() -> TripItinerary {
        TripItinerary(
            summary: summary,
            days: days.map { TripItinerary.Day(title: $0.title, activities: $0.activities) }
        )
    }
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedDay {

    @Guide(description: "Short title for the day (e.g. 'Day 1: Old Town').")
    let title: String

    @Guide(description: "3-5 short activity descriptions.")
    let activities: [String]
}
#endif
