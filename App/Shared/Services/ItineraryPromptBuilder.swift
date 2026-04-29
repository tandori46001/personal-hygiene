import Foundation

/// Round 27 WS-A A7: pure assembly of a `TripItineraryRequest` + `Trip`
/// metadata into the example-template prompt the user can either feed
/// to Apple Intelligence on-device or copy into Claude.ai / ChatGPT /
/// Perplexity for web-grounded planning.
///
/// Stays SwiftUI-free + side-effect-free so it's trivially testable. The
/// output is one big multi-line `String` in the locale we receive at
/// init time (default = `Locale.current`).
public enum ItineraryPromptBuilder {

    public static func build(
        request: TripItineraryRequest,
        trip: Trip,
        locale: Locale = .current,
        now: Date = Date()
    ) -> String {
        var lines: [String] = []
        let lang = languageName(for: locale)

        lines.append(headerLine(request: request, trip: trip, lang: lang))
        lines.append("")
        lines.append("## TRIP BASICS")
        lines.append("")
        lines.append("- Departure date & city: \(formatDate(trip.startDate, locale: locale))")
        lines.append("- Return date & city: \(formatDate(trip.endDate, locale: locale))")
        lines.append("- Destination: \(trip.destinationName.isEmpty ? "—" : trip.destinationName)")
        if !request.transport.isEmpty {
            lines.append("- Transport between cities: \(joinReadable(request.transport.map(transportLabel), separator: ", "))")
        }
        lines.append("- Number of travellers: \(request.travellerCount)")
        if let vibe = request.vibe {
            lines.append("- Trip vibe: \(vibeLabel(vibe))")
        }

        // Accommodation table.
        if !request.nights.isEmpty {
            lines.append("")
            lines.append("## ACCOMMODATION")
            lines.append("")
            lines.append("| Night | Date | City/Area | Type | Status |")
            lines.append("|-------|------|-----------|------|--------|")
            for (idx, night) in request.nights.enumerated() {
                let typeText = night.type.map(accommodationLabel) ?? "—"
                let cityText = night.cityArea.isEmpty ? "—" : night.cityArea
                let status = night.booked ? "✅" : "❌"
                lines.append("| \(idx + 1) | \(formatDate(night.date, locale: locale)) | \(cityText) | \(typeText) | \(status) |")
            }
            if let low = request.accommodationBudgetLow,
               let high = request.accommodationBudgetHigh {
                let currency = request.accommodationCurrency ?? localCurrencyCode(for: locale)
                lines.append("")
                lines.append("Budget per night (unbooked): \(low)–\(high) \(currency)")
            }
            if !request.accommodationPriorities.isEmpty {
                lines.append("Top accommodation priorities: \(joinReadable(request.accommodationPriorities.map(priorityLabel), separator: ", "))")
            }
        }

        // Fixed commitments.
        if !trip.milestones.isEmpty {
            lines.append("")
            lines.append("## FIXED COMMITMENTS (non-negotiable — plan around these)")
            lines.append("")
            let calendar = Calendar.autoupdatingCurrent
            for milestone in trip.milestones {
                if let date = calendar.date(byAdding: .day, value: -milestone.daysBefore, to: trip.startDate) {
                    lines.append("- \(formatDate(date, locale: locale)) — \(milestone.title)")
                } else {
                    lines.append("- \(milestone.title)")
                }
            }
        }

        // Travellers.
        let travellersBlock = travellersSection(request: request)
        if !travellersBlock.isEmpty {
            lines.append("")
            lines.append("## TRAVELLERS")
            lines.append("")
            lines.append(contentsOf: travellersBlock)
        }

        // Interests.
        let interestsBlock = interestsSection(request: request)
        if !interestsBlock.isEmpty {
            lines.append("")
            lines.append("## INTERESTS & PREFERENCES")
            lines.append("")
            lines.append(contentsOf: interestsBlock)
        }

        // Budget.
        let budgetBlock = budgetSection(request: request, locale: locale)
        if !budgetBlock.isEmpty {
            lines.append("")
            lines.append("## BUDGET")
            lines.append("")
            lines.append(contentsOf: budgetBlock)
        }

        // Logistics.
        let logisticsBlock = logisticsSection(request: request)
        if !logisticsBlock.isEmpty {
            lines.append("")
            lines.append("## LOGISTICS")
            lines.append("")
            lines.append(contentsOf: logisticsBlock)
        }

        // Deliverables.
        if !request.deliverables.isEmpty {
            lines.append("")
            lines.append("## DELIVERABLES — produce as separate sections in \(lang)")
            lines.append("")
            for deliverable in Deliverable.allCases where request.deliverables.contains(deliverable) {
                lines.append("\(deliverableNumber(deliverable)). \(deliverableLabel(deliverable))")
            }
        }

        // Verifications.
        if !request.verifications.isEmpty {
            lines.append("")
            lines.append("## BEFORE YOU START — VERIFY ONLINE")
            lines.append("")
            lines.append("Search the web to confirm:")
            for verification in Verification.allCases where request.verifications.contains(verification) {
                lines.append("- \(verificationLabel(verification))")
            }
            lines.append("")
            lines.append("If anything I told you doesn't match what you find, flag it before building the plan.")
        }

        lines.append("")
        lines.append("## NOW PLEASE")
        lines.append("")
        lines.append("Start by confirming you've understood, then run the online checks, flag any issues, and produce the deliverables in \(lang).")

        return lines.joined(separator: "\n")
    }

    // MARK: - Section helpers

    private static func headerLine(request: TripItineraryRequest, trip: Trip, lang: String) -> String {
        var who = ""
        if !request.travellerNamesAndAges.isEmpty {
            who = " — \(request.travellerNamesAndAges)"
        } else if !request.relationships.isEmpty {
            who = " — \(joinReadable(request.relationships.map(relationshipLabel), separator: ", "))"
        }
        return "Plan a trip for \(request.travellerCount) traveller(s)\(who). Reply in \(lang)."
    }

    private static func travellersSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if let fitness = request.fitness {
            out.append("- Fitness level: \(fitnessLabel(fitness))")
        }
        if !request.mobilityNeeds.isEmpty, !request.mobilityNeeds.contains(.none) {
            out.append("- Mobility needs: \(joinReadable(request.mobilityNeeds.map(mobilityLabel), separator: ", "))")
        }
        if !request.dietaryRestrictions.isEmpty, !request.dietaryRestrictions.contains(.none) {
            out.append("- Dietary restrictions: \(joinReadable(request.dietaryRestrictions.map(dietaryLabel), separator: ", "))")
        }
        return out
    }

    private static func interestsSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if !request.mustDoActivities.isEmpty {
            out.append("- Must-do activities: \(joinReadable(request.mustDoActivities.map(activityLabel), separator: ", "))")
        }
        if !request.mustSeePlaces.isEmpty {
            out.append("- Want-to-see places: \(request.mustSeePlaces)")
        }
        if !request.lovedCuisines.isEmpty {
            out.append("- Cuisines I love: \(joinReadable(request.lovedCuisines.map(cuisineLabel), separator: ", "))")
        }
        if !request.avoidedCuisines.isEmpty {
            out.append("- Cuisines to avoid: \(joinReadable(request.avoidedCuisines.map(cuisineLabel), separator: ", "))")
        }
        if let pace = request.pace {
            out.append("- Pace: \(paceLabel(pace))")
        }
        if !request.avoidances.isEmpty {
            out.append("- Avoid: \(joinReadable(request.avoidances.map(avoidanceLabel), separator: ", "))")
        }
        return out
    }

    private static func budgetSection(request: TripItineraryRequest, locale: Locale) -> [String] {
        var out: [String] = []
        let currency = request.budgetCurrency ?? localCurrencyCode(for: locale)
        switch request.budgetMode {
        case .totalTrip:
            if let amount = request.budgetAmount {
                out.append("- Total budget: \(amount) \(currency)")
            }
        case .perDay:
            if let amount = request.budgetAmount {
                out.append("- Per-day target: \(amount) \(currency)/day")
            }
        case .unlimited:
            out.append("- Budget: open-ended (no explicit cap)")
        case .none:
            break
        }
        if let priority = request.budgetPriority {
            out.append("- Priority: \(budgetPriorityLabel(priority))")
        }
        if let food = request.foodBudgetPerMeal {
            out.append("- Per-meal target: \(foodBudgetLabel(food)) \(currency) per person")
        }
        return out
    }

    private static func logisticsSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if let visa = request.visaStatus {
            out.append("- Passport / visa: \(visaLabel(visa))")
        }
        if let insurance = request.travelInsurance {
            out.append("- Travel insurance: \(insuranceLabel(insurance))")
        }
        if let data = request.dataPlan {
            out.append("- Phone / data: \(dataLabel(data))")
        }
        if let driving = request.drivingAbroad {
            out.append("- Driving abroad: \(drivingLabel(driving))")
        }
        if let vacc = request.vaccinations {
            out.append("- Vaccinations: \(vaccinationLabel(vacc))")
        }
        return out
    }

    // MARK: - Label helpers (English natural-language for the prompt itself)

    private static func relationshipLabel(_ r: Relationship) -> String {
        switch r {
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

    private static func fitnessLabel(_ f: FitnessLevel) -> String {
        switch f {
        case .veryLow: "very low"
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .veryHigh: "very high"
        }
    }

    private static func mobilityLabel(_ m: MobilityNeed) -> String {
        switch m {
        case .none: "none"
        case .wheelchair: "wheelchair"
        case .cane: "cane"
        case .avoidStairs: "avoid stairs"
        case .fatigueEasily: "fatigues easily"
        case .other: "other"
        }
    }

    private static func dietaryLabel(_ d: DietaryRestriction) -> String {
        switch d {
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

    private static func vibeLabel(_ v: TripVibe) -> String {
        switch v {
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

    private static func transportLabel(_ t: TransportMode) -> String {
        switch t {
        case .carSelf: "car (I drive)"
        case .carOther: "car (someone else drives)"
        case .plane: "plane"
        case .train: "train"
        case .bus: "bus"
        case .walkBike: "walking / bike"
        case .cruise: "cruise"
        }
    }

    private static func paceLabel(_ p: Pace) -> String {
        switch p {
        case .relaxed: "relaxed (1-2 things/day)"
        case .balanced: "balanced (3-4 things/day)"
        case .packed: "packed (5+ things/day)"
        }
    }

    private static func avoidanceLabel(_ a: Avoidance) -> String {
        switch a {
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

    private static func accommodationLabel(_ a: AccommodationType) -> String {
        switch a {
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

    private static func priorityLabel(_ p: AccommodationPriority) -> String {
        switch p {
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

    private static func activityLabel(_ a: Activity) -> String {
        switch a {
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

    private static func cuisineLabel(_ c: Cuisine) -> String {
        switch c {
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

    private static func budgetPriorityLabel(_ p: BudgetPriority) -> String {
        switch p {
        case .saveWherePossible: "save where possible"
        case .splurgeFood: "splurge on food"
        case .splurgeExperiences: "splurge on experiences"
        case .splurgeLodging: "splurge on lodging"
        case .balanced: "balanced"
        }
    }

    private static func foodBudgetLabel(_ f: FoodBudget) -> String {
        switch f {
        case .under10: "under 10"
        case .mid: "10–30"
        case .splurge: "30+"
        case .mixed: "mix"
        }
    }

    private static func visaLabel(_ v: VisaStatus) -> String {
        switch v {
        case .unsureCheck: "not sure — please verify"
        case .notNeeded: "not needed"
        case .alreadyHave: "already have it"
        case .needToApply: "need to apply"
        }
    }

    private static func insuranceLabel(_ s: TravelInsuranceStatus) -> String {
        switch s {
        case .haveIt: "have it"
        case .needRecommendations: "need recommendations"
        case .declined: "declined"
        }
    }

    private static func dataLabel(_ d: DataPlan) -> String {
        switch d {
        case .haveESIM: "eSIM ready"
        case .needAdvice: "need advice"
        case .haveRoaming: "roaming covered"
        case .notNeeded: "not needed"
        }
    }

    private static func drivingLabel(_ d: DrivingAbroadStatus) -> String {
        switch d {
        case .haveIDP: "international permit ready"
        case .needIDP: "need permit info"
        case .sideOfRoadKnown: "side of the road known"
        }
    }

    private static func vaccinationLabel(_ v: VaccinationStatus) -> String {
        switch v {
        case .noConcerns: "no concerns"
        case .askIfRequired: "please flag any required"
        case .haveSpecificVaccine: "specific vaccine on file"
        }
    }

    private static func deliverableLabel(_ d: Deliverable) -> String {
        switch d {
        case .dayByDay: "Day-by-day itinerary with morning / afternoon / evening blocks (activity + address + estimated cost + travel time + 2-3 food suggestions per day + bad-weather backup)"
        case .packingList: "Master packing list tailored to climate and planned activities"
        case .preTripChecklist: "Pre-trip checklist (bookings to confirm, documents, currency, apps to download)"
        case .budgetEstimate: "Budget estimate broken down by lodging / transport / food / activities / misc"
        case .emergencyInfo: "Emergency info sheet (nearest hospital per stop, emergency numbers, embassy if abroad)"
        case .routesTransportSummary: "Routes & transport summary (distances, drive/flight times, stops along the way)"
        }
    }

    private static func deliverableNumber(_ d: Deliverable) -> Int {
        Deliverable.allCases.firstIndex(of: d).map { $0 + 1 } ?? 0
    }

    private static func verificationLabel(_ v: Verification) -> String {
        switch v {
        case .eventDates: "Event dates, times, venues, ticket availability"
        case .attractionHoursPrices: "Attraction hours and prices for the travel dates (not generic)"
        case .visaBorder: "Border / visa / entry requirements"
        case .weatherForecast: "Weather forecast (if within 10 days)"
        case .closuresStrikesFestivals: "Closures, strikes, festivals, or holidays affecting the dates"
        }
    }

    // MARK: - Locale + format helpers

    private static func languageName(for locale: Locale) -> String {
        let code = locale.language.languageCode?.identifier ?? "en"
        switch code {
        case "es": return "Spanish"
        case "fr": return "French"
        default: return "English"
        }
    }

    private static func localCurrencyCode(for locale: Locale) -> String {
        locale.currency?.identifier ?? "USD"
    }

    private static func formatDate(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func joinReadable(_ items: [String], separator: String) -> String {
        items.filter { !$0.isEmpty }.joined(separator: separator)
    }
}
