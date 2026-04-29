import Foundation

/// Round-28: extracted from `ItineraryPromptBuilder` so the builder
/// file fits SwiftLint's 500-line limit and the cyclomatic-complexity
/// budget. Pure lookup tables — one `String` per enum case, hand-written
/// English (the prompt itself stays in English regardless of locale;
/// the deliverables get translated by the LLM via the language hint).
enum ItineraryPromptLabels {

    static func relationship(_ value: Relationship) -> String {
        switch value {
        case .partner: "partner"
        case .spouse: "spouse"
        case .child: "child(ren)"
        case .parent: "parent(s)"
        case .sibling: "sibling(s)"
        case .friend: "friend(s)"
        case .colleague: "colleague(s)"
        case .solo: "solo traveller"
        }
    }

    static func fitness(_ value: FitnessLevel) -> String {
        switch value {
        case .veryLow: "very low"
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .veryHigh: "very high"
        }
    }

    static func mobility(_ value: MobilityNeed) -> String {
        switch value {
        case .none: "none"
        case .wheelchair: "wheelchair"
        case .cane: "cane"
        case .avoidStairs: "avoid stairs"
        case .fatigueEasily: "fatigues easily"
        case .other: "other"
        }
    }

    static func dietary(_ value: DietaryRestriction) -> String {
        switch value {
        case .none: "none"
        case .vegetarian: "vegetarian"
        case .vegan: "vegan"
        case .pescatarian: "pescatarian"
        case .halal: "halal"
        case .kosher: "kosher"
        case .glutenFree: "gluten-free"
        case .lactoseFree: "lactose-free"
        case .nutAllergy: "nut allergy"
        case .shellfishAllergy: "shellfish allergy"
        case .other: "other"
        }
    }

    static func vibe(_ value: TripVibe) -> String {
        switch value {
        case .honeymoon: "honeymoon"
        case .family: "family"
        case .solo: "solo"
        case .roadTrip: "road trip"
        case .businessLeisure: "business + leisure"
        case .adventure: "adventure"
        case .relaxation: "relaxation"
        case .cultural: "cultural"
        case .foodie: "foodie"
        case .nature: "nature"
        }
    }

    static func transport(_ value: TransportMode) -> String {
        switch value {
        case .carSelf: "car (I drive)"
        case .carOther: "car (someone else drives)"
        case .plane: "plane"
        case .train: "train"
        case .bus: "bus"
        case .walkBike: "walking / bike"
        case .cruise: "cruise"
        }
    }

    static func pace(_ value: Pace) -> String {
        switch value {
        case .relaxed: "relaxed (1-2 things/day)"
        case .balanced: "balanced (3-4 things/day)"
        case .packed: "packed (5+ things/day)"
        }
    }

    static func avoidance(_ value: Avoidance) -> String {
        switch value {
        case .crowds: "crowds"
        case .longDrives: "long drives"
        case .earlyMornings: "early mornings"
        case .spicyFood: "spicy food"
        case .heights: "heights"
        case .cold: "cold"
        case .heat: "heat"
        case .buses: "buses"
        case .longWaits: "long waits"
        }
    }

    static func accommodation(_ value: AccommodationType) -> String {
        switch value {
        case .hotel: "hotel"
        case .airbnb: "Airbnb"
        case .friendsPlace: "friend's place"
        case .camping: "camping"
        case .hostel: "hostel"
        case .resort: "resort"
        case .bnb: "B&B"
        case .cruise: "cruise"
        }
    }

    static func priority(_ value: AccommodationPriority) -> String {
        switch value {
        case .location: "location"
        case .cleanliness: "cleanliness"
        case .breakfast: "breakfast included"
        case .parking: "parking"
        case .petFriendly: "pet-friendly"
        case .pool: "pool"
        case .fastWifi: "fast Wi-Fi"
        case .quiet: "quiet"
        case .familyFriendly: "family-friendly"
        case .views: "views"
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func activity(_ value: Activity) -> String {
        switch value {
        case .zooWildlife: "zoo / wildlife"
        case .hiking: "hiking"
        case .museums: "museums"
        case .beach: "beach"
        case .concerts: "concerts"
        case .nightlife: "nightlife"
        case .shopping: "shopping"
        case .spa: "spa"
        case .foodTours: "food tours"
        case .adventureSports: "adventure sports"
        case .photography: "photography"
        case .architecture: "architecture"
        case .religiousSites: "religious sites"
        case .localMarkets: "local markets"
        case .themeParks: "theme parks"
        }
    }

    static func cuisine(_ value: Cuisine) -> String {
        switch value {
        case .italian: "Italian"
        case .french: "French"
        case .japanese: "Japanese"
        case .mexican: "Mexican"
        case .thai: "Thai"
        case .indian: "Indian"
        case .chinese: "Chinese"
        case .mediterranean: "Mediterranean"
        case .localTraditional: "local traditional"
        case .streetFood: "street food"
        case .seafood: "seafood"
        case .bbq: "BBQ"
        }
    }

    static func budgetPriority(_ value: BudgetPriority) -> String {
        switch value {
        case .saveWherePossible: "save where possible"
        case .splurgeFood: "splurge on food"
        case .splurgeExperiences: "splurge on experiences"
        case .splurgeLodging: "splurge on lodging"
        case .balanced: "balanced"
        }
    }

    static func foodBudget(_ value: FoodBudget) -> String {
        switch value {
        case .under10: "under 10"
        case .mid: "10–30"
        case .splurge: "30+"
        case .mixed: "mix"
        }
    }

    static func visa(_ value: VisaStatus) -> String {
        switch value {
        case .unsureCheck: "not sure — please verify"
        case .notNeeded: "not needed"
        case .alreadyHave: "already have it"
        case .needToApply: "need to apply"
        }
    }

    static func insurance(_ value: TravelInsuranceStatus) -> String {
        switch value {
        case .haveIt: "have it"
        case .needRecommendations: "need recommendations"
        case .declined: "declined"
        }
    }

    static func dataPlan(_ value: DataPlan) -> String {
        switch value {
        case .haveESIM: "eSIM ready"
        case .needAdvice: "need advice"
        case .haveRoaming: "roaming covered"
        case .notNeeded: "not needed"
        }
    }

    static func driving(_ value: DrivingAbroadStatus) -> String {
        switch value {
        case .haveIDP: "international permit ready"
        case .needIDP: "need permit info"
        case .sideOfRoadKnown: "side of the road known"
        }
    }

    static func vaccination(_ value: VaccinationStatus) -> String {
        switch value {
        case .noConcerns: "no concerns"
        case .askIfRequired: "please flag any required"
        case .haveSpecificVaccine: "specific vaccine on file"
        }
    }

    static func deliverable(_ value: Deliverable) -> String {
        switch value {
        case .dayByDay:
            return "Day-by-day itinerary with morning / afternoon / evening blocks "
                + "(activity + address + estimated cost + travel time + 2-3 food "
                + "suggestions per day + bad-weather backup)"
        case .packingList:
            return "Master packing list tailored to climate and planned activities"
        case .preTripChecklist:
            return "Pre-trip checklist (bookings to confirm, documents, currency, apps to download)"
        case .budgetEstimate:
            return "Budget estimate broken down by lodging / transport / food / activities / misc"
        case .emergencyInfo:
            return "Emergency info sheet (nearest hospital per stop, emergency numbers, embassy if abroad)"
        case .routesTransportSummary:
            return "Routes & transport summary (distances, drive/flight times, stops along the way)"
        }
    }

    static func deliverableNumber(_ value: Deliverable) -> Int {
        Deliverable.allCases.firstIndex(of: value).map { $0 + 1 } ?? 0
    }

    static func verification(_ value: Verification) -> String {
        switch value {
        case .eventDates: "Event dates, times, venues, ticket availability"
        case .attractionHoursPrices: "Attraction hours and prices for the travel dates (not generic)"
        case .visaBorder: "Border / visa / entry requirements"
        case .weatherForecast: "Weather forecast (if within 10 days)"
        case .closuresStrikesFestivals: "Closures, strikes, festivals, or holidays affecting the dates"
        }
    }
}
