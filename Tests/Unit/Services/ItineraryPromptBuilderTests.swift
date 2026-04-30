@preconcurrency import XCTest

@testable import PersonalHygiene

final class ItineraryPromptBuilderTests: XCTestCase {

    private func makeTrip(
        name: String = "Test trip",
        destination: String = "Tokyo",
        start: Date = Date(timeIntervalSince1970: 1_800_000_000),
        end: Date = Date(timeIntervalSince1970: 1_801_000_000)
    ) -> Trip {
        Trip(name: name, startDate: start, endDate: end, destinationName: destination)
    }

    // MARK: - Skip-stage = sensible defaults

    func test_emptyRequest_producesUsablePrompt() {
        let trip = makeTrip()
        let prompt = ItineraryPromptBuilder.build(
            request: TripItineraryRequest(),
            trip: trip
        )
        XCTAssertTrue(prompt.contains("TRIP BASICS"))
        XCTAssertTrue(prompt.contains("Tokyo"))
        XCTAssertTrue(prompt.contains("NOW PLEASE"))
        XCTAssertTrue(prompt.contains("DELIVERABLES"))
        XCTAssertTrue(prompt.contains("VERIFY ONLINE"))
    }

    func test_emptyRequest_omitsAccommodationSection() {
        let prompt = ItineraryPromptBuilder.build(
            request: TripItineraryRequest(nights: []),
            trip: makeTrip()
        )
        XCTAssertFalse(prompt.contains("ACCOMMODATION"))
    }

    func test_emptyRequest_omitsTravellersSectionWhenAllNil() {
        let request = TripItineraryRequest(
            mobilityNeeds: [.none],
            dietaryRestrictions: [.none]
        )
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertFalse(prompt.contains("## TRAVELLERS"))
    }

    // MARK: - Stage data lands in the prompt

    func test_vibeAndPace_appearInBasicsAndInterests() {
        let request = TripItineraryRequest(vibe: .honeymoon, pace: .relaxed)
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("Trip vibe: honeymoon"))
        XCTAssertTrue(prompt.contains("relaxed"))
    }

    func test_transportListIsHumanReadable() {
        let request = TripItineraryRequest(transport: [.carSelf, .plane, .train])
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("car (I drive)"))
        XCTAssertTrue(prompt.contains("plane"))
        XCTAssertTrue(prompt.contains("train"))
    }

    func test_accommodationTable_rendered() {
        let request = TripItineraryRequest(
            nights: [
                NightAccommodation(
                    date: Date(timeIntervalSince1970: 1_800_000_000),
                    cityArea: "Shibuya",
                    type: .hotel,
                    booked: true
                ),
                NightAccommodation(
                    date: Date(timeIntervalSince1970: 1_800_086_400),
                    cityArea: "Kyoto",
                    type: .airbnb,
                    booked: false
                ),
            ]
        )
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("ACCOMMODATION"))
        XCTAssertTrue(prompt.contains("Shibuya"))
        XCTAssertTrue(prompt.contains("Kyoto"))
        XCTAssertTrue(prompt.contains("hotel"))
        XCTAssertTrue(prompt.contains("Airbnb"))
        XCTAssertTrue(prompt.contains("✅"))
        XCTAssertTrue(prompt.contains("❌"))
    }

    func test_mustSeePlaces_freeText_appearsVerbatim() {
        let request = TripItineraryRequest(mustSeePlaces: "Coliseo, Trastevere, Vatican Museums")
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("Coliseo, Trastevere, Vatican Museums"))
    }

    func test_dietaryRestrictionsAndCuisines() {
        let request = TripItineraryRequest(
            dietaryRestrictions: [.vegetarian, .glutenFree],
            lovedCuisines: [.italian, .japanese],
            avoidedCuisines: [.bbq]
        )
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("vegetarian"))
        XCTAssertTrue(prompt.contains("gluten-free"))
        XCTAssertTrue(prompt.contains("Italian"))
        XCTAssertTrue(prompt.contains("Japanese"))
        XCTAssertTrue(prompt.contains("BBQ"))
    }

    func test_budgetTotalAndPerDay() {
        let totalRequest = TripItineraryRequest(
            budgetMode: .totalTrip,
            budgetAmount: 3000,
            budgetCurrency: "EUR"
        )
        let totalPrompt = ItineraryPromptBuilder.build(request: totalRequest, trip: makeTrip())
        XCTAssertTrue(totalPrompt.contains("Total budget: 3000 EUR"))

        let dailyRequest = TripItineraryRequest(
            budgetMode: .perDay,
            budgetAmount: 200,
            budgetCurrency: "USD"
        )
        let dailyPrompt = ItineraryPromptBuilder.build(request: dailyRequest, trip: makeTrip())
        XCTAssertTrue(dailyPrompt.contains("Per-day target: 200 USD/day"))
    }

    func test_unlimitedBudget_explicitInPrompt() {
        let request = TripItineraryRequest(budgetMode: .unlimited)
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("open-ended"))
    }

    func test_logisticsCarDriving_onlyShownWhenSet() {
        let request = TripItineraryRequest(drivingAbroad: .needIDP)
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("Driving abroad: need permit info"))
    }

    // MARK: - Deliverables + verifications checklists

    func test_deliverables_allEnabled_listAllSix() {
        let prompt = ItineraryPromptBuilder.build(request: TripItineraryRequest(), trip: makeTrip())
        XCTAssertTrue(prompt.contains("Day-by-day itinerary"))
        XCTAssertTrue(prompt.contains("Master packing list"))
        XCTAssertTrue(prompt.contains("Pre-trip checklist"))
        XCTAssertTrue(prompt.contains("Budget estimate"))
        XCTAssertTrue(prompt.contains("Emergency info sheet"))
        XCTAssertTrue(prompt.contains("Routes & transport summary"))
    }

    func test_deliverables_subset_onlyListsSelected() {
        let request = TripItineraryRequest(
            deliverables: [.dayByDay, .packingList]
        )
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertTrue(prompt.contains("Day-by-day"))
        XCTAssertTrue(prompt.contains("Master packing list"))
        XCTAssertFalse(prompt.contains("Emergency info"))
    }

    func test_verifications_emptyDoesNotEmitSection() {
        let request = TripItineraryRequest(verifications: [])
        let prompt = ItineraryPromptBuilder.build(request: request, trip: makeTrip())
        XCTAssertFalse(prompt.contains("VERIFY ONLINE"))
    }

    // MARK: - Locale-aware language hint

    func test_spanishLocale_setsLanguageInstruction() {
        let spanish = Locale(identifier: "es_ES")
        let prompt = ItineraryPromptBuilder.build(
            request: TripItineraryRequest(),
            trip: makeTrip(),
            locale: spanish
        )
        XCTAssertTrue(prompt.contains("Reply in Spanish"))
        XCTAssertTrue(prompt.contains("DELIVERABLES — produce as separate sections in Spanish"))
    }

    func test_frenchLocale_setsLanguageInstruction() {
        let french = Locale(identifier: "fr_FR")
        let prompt = ItineraryPromptBuilder.build(
            request: TripItineraryRequest(),
            trip: makeTrip(),
            locale: french
        )
        XCTAssertTrue(prompt.contains("Reply in French"))
    }
}
