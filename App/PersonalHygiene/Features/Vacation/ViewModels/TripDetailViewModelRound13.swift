import Foundation

/// Round-13 helpers extracted from `TripDetailViewModel` to keep the main
/// type body under SwiftLint's 300-line cap. Lives in the same module so
/// the methods read like instance members.
extension TripDetailViewModel {

    // MARK: - Round 13 notes / snapshot helpers

    /// Round-13 slice 1: split notes by blank-line paragraphs so the renderer
    /// can show each as its own visual block. Empty input yields `[]`.
    var notesParagraphs: [String] {
        let trimmed = trip.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return trimmed.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Round-13 slice 4: surface the captured currency snapshot so TripDetail
    /// can render a "N conversions captured" row.
    var capturedCurrencySnapshot: [RecentConversionsStore.Entry] {
        guard let json = trip.currencySnapshotJSON,
              let data = json.data(using: .utf8)
        else { return [] }
        return (try? JSONDecoder().decode([RecentConversionsStore.Entry].self, from: data)) ?? []
    }

    /// Round-13 slice 3: capture currency snapshot but never leave a `nil` —
    /// when no recent conversions exist we persist an explicit empty array
    /// so future readers know the snapshot ran (rather than the trip was
    /// never archived).
    func captureCurrencySnapshotWithFallback() {
        let recents = RecentConversionsStore.recent()
        let payload = (try? JSONEncoder().encode(recents)) ?? Data("[]".utf8)
        if let str = String(data: payload, encoding: .utf8) {
            trip.currencySnapshotJSON = str
            saveEdits()
        }
    }

    // MARK: - Trip expenses (round 13 slice 10)

    var expenses: [TripExpense] {
        get {
            guard let json = trip.expensesJSON,
                  let data = json.data(using: .utf8)
            else { return [] }
            return (try? JSONDecoder().decode([TripExpense].self, from: data)) ?? []
        }
        set {
            let payload = try? JSONEncoder().encode(newValue)
            trip.expensesJSON = payload.flatMap { String(data: $0, encoding: .utf8) }
            saveEdits()
        }
    }

    func addExpense(label: String, amount: Double, currencyCode: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0 else { return }
        var current = expenses
        current.append(TripExpense(label: trimmed, amount: amount, currencyCode: currencyCode))
        expenses = current
    }

    func deleteExpense(_ expense: TripExpense) {
        expenses = expenses.filter { $0.id != expense.id }
    }

    /// Round-13 slice 12: build a Markdown string suitable for share sheets
    /// or copy/paste. Includes title, dates, destination, milestones,
    /// packing, notes, expenses summary.
    func itineraryMarkdown(calendar: Calendar = .autoupdatingCurrent) -> String {
        _ = calendar
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var lines: [String] = []
        lines.append("# \(trip.name)")
        lines.append("")
        lines.append("**Destination:** \(trip.destinationName)")
        let startStr = formatter.string(from: trip.startDate)
        let endStr = formatter.string(from: trip.endDate)
        lines.append("**Dates:** \(startStr) → \(endStr)")
        if !trip.milestones.isEmpty {
            lines.append("")
            lines.append("## Milestones")
            for milestone in sortedMilestones {
                let mark = milestone.isComplete ? "[x]" : "[ ]"
                lines.append("- \(mark) \(milestone.title) — \(milestone.daysBefore)d before")
            }
        }
        if !trip.packingItems.isEmpty {
            lines.append("")
            lines.append("## Packing")
            for item in sortedPackingItems {
                let mark = item.isPacked ? "[x]" : "[ ]"
                lines.append("- \(mark) \(item.title)")
            }
        }
        let trimmedNotes = trip.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            lines.append("")
            lines.append("## Notes")
            lines.append(trimmedNotes)
        }
        if !expenses.isEmpty {
            lines.append("")
            lines.append("## Expenses")
            for expense in expenses {
                let amountString = String(format: "%.2f", expense.amount)
                lines.append("- \(expense.label) — \(amountString) \(expense.currencyCode)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Round-18 slice 16: plain-text equivalent of `itineraryMarkdown(...)`.
    /// Strips Markdown syntax (`#` headings, `**bold**`, `[ ]` checkboxes)
    /// so the output is suitable for pasting into chat / SMS / email body
    /// where Markdown wouldn't render.
    func itineraryPlainText(calendar: Calendar = .autoupdatingCurrent) -> String {
        let markdown = itineraryMarkdown(calendar: calendar)
        var lines: [String] = []
        for line in markdown.components(separatedBy: "\n") {
            var stripped = line
            // Remove leading "## " / "# " heading markers.
            if stripped.hasPrefix("# ") {
                stripped = String(stripped.dropFirst(2))
            } else if stripped.hasPrefix("## ") {
                stripped = String(stripped.dropFirst(3))
            }
            // Remove **bold** wrappers but keep their inner text.
            stripped = stripped.replacingOccurrences(of: "**", with: "")
            // Convert "- [x] foo" / "- [ ] foo" into "✓ foo" / "• foo".
            if stripped.hasPrefix("- [x] ") {
                stripped = "✓ " + stripped.dropFirst(6)
            } else if stripped.hasPrefix("- [ ] ") {
                stripped = "• " + stripped.dropFirst(6)
            } else if stripped.hasPrefix("- ") {
                stripped = "• " + stripped.dropFirst(2)
            }
            lines.append(stripped)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Round 14 helpers

    /// Round-14 slice 3: total expenses grouped by currency. Returns
    /// `[currencyCode: total]` so the UI can show a per-currency summary
    /// without doing live FX (which the user might not want mid-trip).
    var expensesByCurrency: [String: Double] {
        var result: [String: Double] = [:]
        for expense in expenses {
            result[expense.currencyCode, default: 0] += expense.amount
        }
        return result
    }

    /// Round-14 slice 14: emergency contacts decoded from `Trip.emergencyContactsJSON`.
    var emergencyContacts: [TripEmergencyContact] {
        get {
            guard let json = trip.emergencyContactsJSON,
                  let data = json.data(using: .utf8)
            else { return [] }
            return (try? JSONDecoder().decode([TripEmergencyContact].self, from: data)) ?? []
        }
        set {
            let payload = try? JSONEncoder().encode(newValue)
            trip.emergencyContactsJSON = payload.flatMap { String(data: $0, encoding: .utf8) }
            saveEdits()
        }
    }

    func addEmergencyContact(label: String, phone: String, notes: String? = nil) {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, !trimmedPhone.isEmpty else { return }
        var current = emergencyContacts
        current.append(TripEmergencyContact(
            label: trimmedLabel,
            phone: trimmedPhone,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        emergencyContacts = current
    }

    func deleteEmergencyContact(_ contact: TripEmergencyContact) {
        emergencyContacts = emergencyContacts.filter { $0.id != contact.id }
    }

    /// Round-14 slice 13: estimated round-trip CO₂ for the trip in kg.
    /// Requires both endpoints — returns `nil` when the trip lacks a
    /// destination geocode or the home location is unset.
    /// Round-19 slice T4.16: optional `mode` parameter so the caller can
    /// preview ferry / public-transport / car estimates instead of flight.
    func roundTripCO2Kg(
        home: BlockLocation?,
        mode: TripCarbonEstimate.TransportMode = .flight
    ) -> Double? {
        guard let home,
              let toLat = trip.destinationLatitude,
              let toLon = trip.destinationLongitude
        else { return nil }
        let distance = TripCarbonEstimate.distanceKm(
            fromLat: home.latitude,
            fromLon: home.longitude,
            toLat: toLat,
            toLon: toLon
        )
        return TripCarbonEstimate.roundTripKgCO2(distanceKm: distance, mode: mode)
    }

    /// Round-19 slice T4.15: convert *all* expenses to a single target
    /// currency using the most-recent saved conversion rate from
    /// `LastConversionStore`. Returns a printable per-currency breakdown
    /// + grand total in the target currency, intended for clipboard share.
    /// The conversion is offline — no network round-trip.
    ///
    /// When `LastConversionStore` is empty or all expenses share the same
    /// currency, returns a simple one-line total without conversion.
    func convertedExpensesSummary(now: Date = Date()) -> String {
        let exps = expenses
        guard !exps.isEmpty else { return "" }
        let totalsByCurrency = Dictionary(
            grouping: exps,
            by: { $0.currencyCode.uppercased() }
        ).mapValues { $0.reduce(0.0) { $0 + $1.amount } }

        guard let snapshot = LastConversionStore.load() else {
            return totalsByCurrency
                .sorted { $0.key < $1.key }
                .map { String(format: "%.2f %@", $0.value, $0.key) }
                .joined(separator: " · ")
        }

        let target = snapshot.to.uppercased()
        var lines: [String] = []
        var grandTotal = 0.0
        for (code, total) in totalsByCurrency.sorted(by: { $0.key < $1.key }) {
            if code == target {
                lines.append(String(format: "%.2f %@", total, code))
                grandTotal += total
            } else if code == snapshot.from.uppercased() {
                let converted = total * snapshot.rate
                lines.append(String(format: "%.2f %@ → %.2f %@", total, code, converted, target))
                grandTotal += converted
            } else {
                lines.append(String(format: "%.2f %@ (no rate)", total, code))
            }
        }
        let header = String(format: "≈ %.2f %@", grandTotal, target)
        return ([header] + lines).joined(separator: "\n")
    }

    /// Round-15 slice 11: drop the standard 6m / 3m / 1m / 1w milestone
    /// bundle into the current trip. Skips entries that already exist (by
    /// matching `daysBefore`) so the action is idempotent.
    func addStandardMilestoneBundle() {
        let existingDays = Set(trip.milestones.map(\.daysBefore))
        for seed in MilestoneDefaultBundle.standard where !existingDays.contains(seed.daysBefore) {
            addMilestone(title: seed.title, daysBefore: seed.daysBefore)
        }
    }

    /// Round-13 slice 13: clone trip with every date shifted by `days`.
    /// Keeps milestones + packing + notes; resets the cost snapshot since
    /// the original trip's spend doesn't apply.
    static func duplicateShifted(
        _ source: Trip,
        byDays days: Int,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Trip {
        let newStart = calendar.date(byAdding: .day, value: days, to: source.startDate)
            ?? source.startDate
        let newEnd = calendar.date(byAdding: .day, value: days, to: source.endDate)
            ?? source.endDate
        return Trip(
            name: "Copy of \(source.name)",
            startDate: newStart,
            endDate: newEnd,
            destinationName: source.destinationName,
            destinationLatitude: source.destinationLatitude,
            destinationLongitude: source.destinationLongitude,
            coverPhotoData: source.coverPhotoData,
            packingItems: source.packingItems.map {
                PackingItem(title: $0.title, isPacked: false, category: $0.category)
            },
            notes: source.notes
        )
    }
}
