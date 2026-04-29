import Foundation

/// Round 27 (WS-A) — answers gathered by the AI-itinerary wizard. Persisted
/// as JSON inside `Trip.itineraryRequestJSON` so we don't add a SwiftData
/// migration. Re-opening the wizard for the same trip pre-fills with the
/// previous answers.
///
/// Nothing here is required — every field is optional / has a sensible
/// default. The wizard's "Skip stage" button leaves a stage's fields nil
/// and `ItineraryPromptBuilder` fills in placeholders or omits the section
/// entirely.
public struct TripItineraryRequest: Codable, Sendable, Equatable {

    // MARK: - Stage 1 · Travellers

    public var travellerCount: Int
    public var relationships: [Relationship]
    public var fitness: FitnessLevel?
    public var mobilityNeeds: [MobilityNeed]
    public var dietaryRestrictions: [DietaryRestriction]
    public var travellerNamesAndAges: String

    // MARK: - Stage 2 · Style + transport

    public var vibe: TripVibe?
    public var transport: [TransportMode]
    public var pace: Pace?
    public var avoidances: [Avoidance]

    // MARK: - Stage 3 · Accommodation

    public var nights: [NightAccommodation]
    public var accommodationBudgetLow: Int?
    public var accommodationBudgetHigh: Int?
    public var accommodationCurrency: String?
    public var accommodationPriorities: [AccommodationPriority]

    // MARK: - Stage 4 · Interests

    public var mustDoActivities: [Activity]
    public var lovedCuisines: [Cuisine]
    public var avoidedCuisines: [Cuisine]
    public var mustSeePlaces: String

    // MARK: - Stage 5 · Budget + logistics + deliverables

    public var budgetMode: BudgetMode?
    public var budgetAmount: Int?
    public var budgetCurrency: String?
    public var budgetPriority: BudgetPriority?
    public var foodBudgetPerMeal: FoodBudget?

    public var visaStatus: VisaStatus?
    public var travelInsurance: TravelInsuranceStatus?
    public var dataPlan: DataPlan?
    public var drivingAbroad: DrivingAbroadStatus?
    public var vaccinations: VaccinationStatus?

    public var deliverables: Set<Deliverable>
    public var verifications: Set<Verification>

    public init(
        travellerCount: Int = 1,
        relationships: [Relationship] = [],
        fitness: FitnessLevel? = nil,
        mobilityNeeds: [MobilityNeed] = [],
        dietaryRestrictions: [DietaryRestriction] = [],
        travellerNamesAndAges: String = "",
        vibe: TripVibe? = nil,
        transport: [TransportMode] = [],
        pace: Pace? = nil,
        avoidances: [Avoidance] = [],
        nights: [NightAccommodation] = [],
        accommodationBudgetLow: Int? = nil,
        accommodationBudgetHigh: Int? = nil,
        accommodationCurrency: String? = nil,
        accommodationPriorities: [AccommodationPriority] = [],
        mustDoActivities: [Activity] = [],
        lovedCuisines: [Cuisine] = [],
        avoidedCuisines: [Cuisine] = [],
        mustSeePlaces: String = "",
        budgetMode: BudgetMode? = nil,
        budgetAmount: Int? = nil,
        budgetCurrency: String? = nil,
        budgetPriority: BudgetPriority? = nil,
        foodBudgetPerMeal: FoodBudget? = nil,
        visaStatus: VisaStatus? = nil,
        travelInsurance: TravelInsuranceStatus? = nil,
        dataPlan: DataPlan? = nil,
        drivingAbroad: DrivingAbroadStatus? = nil,
        vaccinations: VaccinationStatus? = nil,
        deliverables: Set<Deliverable> = Set(Deliverable.allCases),
        verifications: Set<Verification> = Set(Verification.allCases)
    ) {
        self.travellerCount = travellerCount
        self.relationships = relationships
        self.fitness = fitness
        self.mobilityNeeds = mobilityNeeds
        self.dietaryRestrictions = dietaryRestrictions
        self.travellerNamesAndAges = travellerNamesAndAges
        self.vibe = vibe
        self.transport = transport
        self.pace = pace
        self.avoidances = avoidances
        self.nights = nights
        self.accommodationBudgetLow = accommodationBudgetLow
        self.accommodationBudgetHigh = accommodationBudgetHigh
        self.accommodationCurrency = accommodationCurrency
        self.accommodationPriorities = accommodationPriorities
        self.mustDoActivities = mustDoActivities
        self.lovedCuisines = lovedCuisines
        self.avoidedCuisines = avoidedCuisines
        self.mustSeePlaces = mustSeePlaces
        self.budgetMode = budgetMode
        self.budgetAmount = budgetAmount
        self.budgetCurrency = budgetCurrency
        self.budgetPriority = budgetPriority
        self.foodBudgetPerMeal = foodBudgetPerMeal
        self.visaStatus = visaStatus
        self.travelInsurance = travelInsurance
        self.dataPlan = dataPlan
        self.drivingAbroad = drivingAbroad
        self.vaccinations = vaccinations
        self.deliverables = deliverables
        self.verifications = verifications
    }
}

// MARK: - Stage 1 enums

public enum Relationship: String, Codable, CaseIterable, Sendable {
    case partner, spouse, child, parent, sibling, friend, colleague, solo
}

public enum FitnessLevel: String, Codable, CaseIterable, Sendable {
    case veryLow, low, medium, high, veryHigh
}

public enum MobilityNeed: String, Codable, CaseIterable, Sendable {
    case none, wheelchair, cane, avoidStairs, fatigueEasily, other
}

public enum DietaryRestriction: String, Codable, CaseIterable, Sendable {
    case none, vegetarian, vegan, pescatarian, halal, kosher
    case glutenFree, lactoseFree, nutAllergy, shellfishAllergy, other
}

// MARK: - Stage 2 enums

public enum TripVibe: String, Codable, CaseIterable, Sendable {
    case honeymoon, family, solo, roadTrip, businessLeisure
    case adventure, relaxation, cultural, foodie, nature
}

public enum TransportMode: String, Codable, CaseIterable, Sendable {
    case carSelf, carOther, plane, train, bus, walkBike, cruise
}

public enum Pace: String, Codable, CaseIterable, Sendable {
    case relaxed, balanced, packed
}

public enum Avoidance: String, Codable, CaseIterable, Sendable {
    case crowds, longDrives, earlyMornings, spicyFood, heights
    case cold, heat, buses, longWaits
}

// MARK: - Stage 3 types

public struct NightAccommodation: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var date: Date
    public var cityArea: String
    public var type: AccommodationType?
    public var booked: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        cityArea: String = "",
        type: AccommodationType? = nil,
        booked: Bool = false
    ) {
        self.id = id
        self.date = date
        self.cityArea = cityArea
        self.type = type
        self.booked = booked
    }
}

public enum AccommodationType: String, Codable, CaseIterable, Sendable {
    case hotel, airbnb, friendsPlace, camping, hostel, resort, bnb, cruise
}

public enum AccommodationPriority: String, Codable, CaseIterable, Sendable {
    case location, cleanliness, breakfast, parking, petFriendly
    case pool, fastWifi, quiet, familyFriendly, views
}

// MARK: - Stage 4 enums

public enum Activity: String, Codable, CaseIterable, Sendable {
    case zooWildlife, hiking, museums, beach, concerts, nightlife
    case shopping, spa, foodTours, adventureSports, photography
    case architecture, religiousSites, localMarkets, themeParks
}

public enum Cuisine: String, Codable, CaseIterable, Sendable {
    case italian, french, japanese, mexican, thai, indian, chinese
    case mediterranean, localTraditional, streetFood, seafood, bbq
}

// MARK: - Stage 5 enums

public enum BudgetMode: String, Codable, CaseIterable, Sendable {
    case totalTrip, perDay, unlimited
}

public enum BudgetPriority: String, Codable, CaseIterable, Sendable {
    case saveWherePossible, splurgeFood, splurgeExperiences, splurgeLodging, balanced
}

public enum FoodBudget: String, Codable, CaseIterable, Sendable {
    case under10, mid, splurge, mixed
}

public enum VisaStatus: String, Codable, CaseIterable, Sendable {
    case unsureCheck, notNeeded, alreadyHave, needToApply
}

public enum TravelInsuranceStatus: String, Codable, CaseIterable, Sendable {
    case haveIt, needRecommendations, declined
}

public enum DataPlan: String, Codable, CaseIterable, Sendable {
    case haveESIM, needAdvice, haveRoaming, notNeeded
}

public enum DrivingAbroadStatus: String, Codable, CaseIterable, Sendable {
    case haveIDP, needIDP, sideOfRoadKnown
}

public enum VaccinationStatus: String, Codable, CaseIterable, Sendable {
    case noConcerns, askIfRequired, haveSpecificVaccine
}

public enum Deliverable: String, Codable, CaseIterable, Sendable {
    case dayByDay, packingList, preTripChecklist, budgetEstimate
    case emergencyInfo, routesTransportSummary
}

public enum Verification: String, Codable, CaseIterable, Sendable {
    case eventDates, attractionHoursPrices, visaBorder
    case weatherForecast, closuresStrikesFestivals
}

// MARK: - Codec

extension TripItineraryRequest {

    /// Decodes the JSON payload from `Trip.itineraryRequestJSON`. Returns
    /// nil if the field is empty/malformed; caller can fall back to
    /// `TripItineraryRequest()` defaults.
    public static func decode(_ json: String?) -> TripItineraryRequest? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(TripItineraryRequest.self, from: data)
    }

    /// Encodes for storage in `Trip.itineraryRequestJSON`. Returns nil if
    /// encoding fails (shouldn't happen for value types).
    public func encoded() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
