import Foundation

/// Round 27 WS-A A7 / round-28 split: pure assembly of a
/// `TripItineraryRequest` + `Trip` metadata into the example-template
/// prompt the user can either feed to Apple Intelligence on-device or
/// copy into Claude.ai / ChatGPT / Perplexity for web-grounded planning.
///
/// Stays SwiftUI-free + side-effect-free so it's trivially testable.
/// Per-enum natural-language labels live in `ItineraryPromptLabels` so
/// this file fits SwiftLint's 500-line + cyclomatic-complexity budget.
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
        lines.append(contentsOf: basicsBlock(request: request, trip: trip, locale: locale))
        lines.append(contentsOf: accommodationBlock(request: request, locale: locale))
        lines.append(contentsOf: commitmentsBlock(trip: trip, locale: locale))
        lines.append(contentsOf: namedSection(title: "TRAVELLERS", body: travellersSection(request: request)))
        lines.append(contentsOf: namedSection(
            title: "INTERESTS & PREFERENCES",
            body: interestsSection(request: request)
        ))
        lines.append(contentsOf: namedSection(
            title: "BUDGET",
            body: budgetSection(request: request, locale: locale)
        ))
        lines.append(contentsOf: namedSection(title: "LOGISTICS", body: logisticsSection(request: request)))
        lines.append(contentsOf: deliverablesBlock(request: request, lang: lang))
        lines.append(contentsOf: verificationsBlock(request: request))
        lines.append("")
        lines.append("## NOW PLEASE")
        lines.append("")
        lines.append(
            "Start by confirming you've understood, then run the online checks, "
            + "flag any issues, and produce the deliverables in \(lang)."
        )
        return lines.joined(separator: "\n")
    }

    // MARK: - Block builders

    private static func basicsBlock(
        request: TripItineraryRequest,
        trip: Trip,
        locale: Locale
    ) -> [String] {
        var out = ["", "## TRIP BASICS", ""]
        out.append("- Departure date & city: \(formatDate(trip.startDate, locale: locale))")
        out.append("- Return date & city: \(formatDate(trip.endDate, locale: locale))")
        out.append("- Destination: \(trip.destinationName.isEmpty ? "—" : trip.destinationName)")
        if !request.transport.isEmpty {
            let labels = request.transport.map(ItineraryPromptLabels.transport)
            out.append("- Transport between cities: \(joinReadable(labels, separator: ", "))")
        }
        out.append("- Number of travellers: \(request.travellerCount)")
        if let vibe = request.vibe {
            out.append("- Trip vibe: \(ItineraryPromptLabels.vibe(vibe))")
        }
        return out
    }

    private static func accommodationBlock(
        request: TripItineraryRequest,
        locale: Locale
    ) -> [String] {
        guard !request.nights.isEmpty else { return [] }
        var out = ["", "## ACCOMMODATION", "",
                   "| Night | Date | City/Area | Type | Status |",
                   "|-------|------|-----------|------|--------|"]
        for (idx, night) in request.nights.enumerated() {
            let typeText = night.type.map(ItineraryPromptLabels.accommodation) ?? "—"
            let cityText = night.cityArea.isEmpty ? "—" : night.cityArea
            let status = night.booked ? "✅" : "❌"
            let dateText = formatDate(night.date, locale: locale)
            out.append("| \(idx + 1) | \(dateText) | \(cityText) | \(typeText) | \(status) |")
        }
        if let low = request.accommodationBudgetLow,
           let high = request.accommodationBudgetHigh {
            let currency = request.accommodationCurrency ?? localCurrencyCode(for: locale)
            out.append("")
            out.append("Budget per night (unbooked): \(low)–\(high) \(currency)")
        }
        if !request.accommodationPriorities.isEmpty {
            let labels = request.accommodationPriorities.map(ItineraryPromptLabels.priority)
            out.append("Top accommodation priorities: \(joinReadable(labels, separator: ", "))")
        }
        return out
    }

    private static func commitmentsBlock(trip: Trip, locale: Locale) -> [String] {
        guard !trip.milestones.isEmpty else { return [] }
        var out = ["", "## FIXED COMMITMENTS (non-negotiable — plan around these)", ""]
        let calendar = Calendar.autoupdatingCurrent
        for milestone in trip.milestones {
            if let date = calendar.date(byAdding: .day, value: -milestone.daysBefore, to: trip.startDate) {
                out.append("- \(formatDate(date, locale: locale)) — \(milestone.title)")
            } else {
                out.append("- \(milestone.title)")
            }
        }
        return out
    }

    private static func deliverablesBlock(request: TripItineraryRequest, lang: String) -> [String] {
        guard !request.deliverables.isEmpty else { return [] }
        var out = ["", "## DELIVERABLES — produce as separate sections in \(lang)", ""]
        for deliverable in Deliverable.allCases where request.deliverables.contains(deliverable) {
            let number = ItineraryPromptLabels.deliverableNumber(deliverable)
            let label = ItineraryPromptLabels.deliverable(deliverable)
            out.append("\(number). \(label)")
        }
        return out
    }

    private static func verificationsBlock(request: TripItineraryRequest) -> [String] {
        guard !request.verifications.isEmpty else { return [] }
        var out = ["", "## BEFORE YOU START — VERIFY ONLINE", "",
                   "Search the web to confirm:"]
        for verification in Verification.allCases where request.verifications.contains(verification) {
            out.append("- \(ItineraryPromptLabels.verification(verification))")
        }
        out.append("")
        out.append("If anything I told you doesn't match what you find, flag it before building the plan.")
        return out
    }

    // MARK: - Section helpers

    private static func namedSection(title: String, body: [String]) -> [String] {
        guard !body.isEmpty else { return [] }
        return ["", "## \(title)", ""] + body
    }

    private static func headerLine(request: TripItineraryRequest, trip: Trip, lang: String) -> String {
        var who = ""
        if !request.travellerNamesAndAges.isEmpty {
            who = " — \(request.travellerNamesAndAges)"
        } else if !request.relationships.isEmpty {
            let labels = request.relationships.map(ItineraryPromptLabels.relationship)
            who = " — \(joinReadable(labels, separator: ", "))"
        }
        return "Plan a trip for \(request.travellerCount) traveller(s)\(who). Reply in \(lang)."
    }

    private static func travellersSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if let fitness = request.fitness {
            out.append("- Fitness level: \(ItineraryPromptLabels.fitness(fitness))")
        }
        if !request.mobilityNeeds.isEmpty, !request.mobilityNeeds.contains(.none) {
            let labels = request.mobilityNeeds.map(ItineraryPromptLabels.mobility)
            out.append("- Mobility needs: \(joinReadable(labels, separator: ", "))")
        }
        if !request.dietaryRestrictions.isEmpty, !request.dietaryRestrictions.contains(.none) {
            let labels = request.dietaryRestrictions.map(ItineraryPromptLabels.dietary)
            out.append("- Dietary restrictions: \(joinReadable(labels, separator: ", "))")
        }
        return out
    }

    private static func interestsSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if !request.mustDoActivities.isEmpty {
            let labels = request.mustDoActivities.map(ItineraryPromptLabels.activity)
            out.append("- Must-do activities: \(joinReadable(labels, separator: ", "))")
        }
        if !request.mustSeePlaces.isEmpty {
            out.append("- Want-to-see places: \(request.mustSeePlaces)")
        }
        if !request.lovedCuisines.isEmpty {
            let labels = request.lovedCuisines.map(ItineraryPromptLabels.cuisine)
            out.append("- Cuisines I love: \(joinReadable(labels, separator: ", "))")
        }
        if !request.avoidedCuisines.isEmpty {
            let labels = request.avoidedCuisines.map(ItineraryPromptLabels.cuisine)
            out.append("- Cuisines to avoid: \(joinReadable(labels, separator: ", "))")
        }
        if let pace = request.pace {
            out.append("- Pace: \(ItineraryPromptLabels.pace(pace))")
        }
        if !request.avoidances.isEmpty {
            let labels = request.avoidances.map(ItineraryPromptLabels.avoidance)
            out.append("- Avoid: \(joinReadable(labels, separator: ", "))")
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
            out.append("- Priority: \(ItineraryPromptLabels.budgetPriority(priority))")
        }
        if let food = request.foodBudgetPerMeal {
            out.append("- Per-meal target: \(ItineraryPromptLabels.foodBudget(food)) \(currency) per person")
        }
        return out
    }

    private static func logisticsSection(request: TripItineraryRequest) -> [String] {
        var out: [String] = []
        if let visa = request.visaStatus {
            out.append("- Passport / visa: \(ItineraryPromptLabels.visa(visa))")
        }
        if let insurance = request.travelInsurance {
            out.append("- Travel insurance: \(ItineraryPromptLabels.insurance(insurance))")
        }
        if let data = request.dataPlan {
            out.append("- Phone / data: \(ItineraryPromptLabels.dataPlan(data))")
        }
        if let driving = request.drivingAbroad {
            out.append("- Driving abroad: \(ItineraryPromptLabels.driving(driving))")
        }
        if let vacc = request.vaccinations {
            out.append("- Vaccinations: \(ItineraryPromptLabels.vaccination(vacc))")
        }
        return out
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
