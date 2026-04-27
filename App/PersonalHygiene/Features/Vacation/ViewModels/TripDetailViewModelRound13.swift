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
