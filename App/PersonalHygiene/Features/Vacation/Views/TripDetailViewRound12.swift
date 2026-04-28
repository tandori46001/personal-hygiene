import SwiftUI
import UIKit

/// Round-12 helpers extracted from `TripDetailView` to keep the main view
/// type body under SwiftLint's 300-line cap.
struct TripDetailExportPayload: Identifiable {
    let id = UUID()
    let url: URL
}

extension TripDetailView {

    @ViewBuilder
    var tripActionMenu: some View {
        Menu {
            Button {
                exportPDF()
            } label: {
                Label {
                    Text("trip.action.share", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            Button {
                shareMarkdown()
            } label: {
                Label {
                    Text("trip.action.shareMarkdown", bundle: .main)
                } icon: {
                    Image(systemName: "doc.text")
                }
            }
            // Round-18 slice 16: plain-text variant for paste into chat/SMS/email.
            Button {
                UIPasteboard.general.string = viewModel.itineraryPlainText()
            } label: {
                Label {
                    Text("trip.action.copyPlainText", bundle: .main)
                } icon: {
                    Image(systemName: "doc.on.doc")
                }
            }
            if viewModel.isStillActive() {
                Button(role: .destructive) {
                    showingArchiveConfirm = true
                } label: {
                    Label {
                        Text("trip.action.archive", bundle: .main)
                    } icon: {
                        Image(systemName: "archivebox")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(Text("trip.action.menu", bundle: .main))
    }

    func shareMarkdown() {
        let markdown = viewModel.itineraryMarkdown()
        let safeName = viewModel.trip.name
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = "\(safeName.isEmpty ? "Trip" : safeName).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try markdown.data(using: .utf8)?.write(to: url, options: .atomic)
            pendingMarkdownShare = TripDetailExportPayload(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    func exportPDF() {
        let bytes = TripPDFExporter.render(trip: viewModel.trip)
        let safeName = viewModel.trip.name
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = "\(safeName.isEmpty ? "Trip" : safeName).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try bytes.write(to: url, options: .atomic)
            pendingExport = TripDetailExportPayload(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    func deleteMilestones(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteMilestone(viewModel.sortedMilestones[idx])
        }
    }

    func deleteDocuments(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteDocument(viewModel.sortedDocuments[idx])
        }
    }

    /// A milestone "has fired" when its computed notification trigger date
    /// (`tripStart - daysBefore` at 09:00 local) is in the past.
    func hasFired(_ milestone: TripMilestone) -> Bool {
        let cal = Calendar.autoupdatingCurrent
        let tripStart = viewModel.trip.startDate
        guard let triggerDay = cal.date(byAdding: .day, value: -milestone.daysBefore, to: tripStart) else {
            return false
        }
        let dayStart = cal.startOfDay(for: triggerDay)
        guard let triggerAtNine = cal.date(byAdding: .hour, value: 9, to: dayStart) else {
            return false
        }
        return triggerAtNine <= Date()
    }
}

/// Round-12 slice 9 + round-13 slice 1: notes section. Round-13: render each
/// `\n\n`-separated paragraph as its own visual block instead of collapsing
/// everything into one Text.
struct TripNotesSection: View {
    @Bindable var viewModel: TripDetailViewModel

    var body: some View {
        Section {
            TextField(
                text: $viewModel.draftNotes,
                prompt: Text("trip.notes.placeholder", bundle: .main),
                axis: .vertical
            ) {
                Text("trip.notes.label", bundle: .main)
            }
            .lineLimit(3...8)
            ForEach(Array(viewModel.notesParagraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(.init(paragraph))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("trip.detail.section.notes", bundle: .main)
        } footer: {
            Text("trip.detail.section.notes.footer", bundle: .main)
        }
    }
}

/// Round-16: trip carbon footprint estimate when geocoded + home location set.
struct TripCarbonSection: View {
    let viewModel: TripDetailViewModel
    let homeLocation: BlockLocation?

    /// Round-18 slice 15: persisted user preference for the displayed unit.
    /// "kg" = kilograms (default), "lb" = pounds. 1 kg ≈ 2.2046 lb.
    @AppStorage("trip.carbon.unit") private var unit: String = "kg"
    /// Round-19 slice T4.16: persisted transport mode preference. Mirrors
    /// `TripCarbonEstimate.TransportMode.rawValue` ("flight" | "ferry" |
    /// "publicTransport" | "car"). Default = flight to keep parity with the
    /// round-14 / round-16 behavior.
    @AppStorage("trip.carbon.mode") private var modeRaw: String = "flight"

    private static let kgToLb = 2.2046226218

    private var mode: TripCarbonEstimate.TransportMode {
        TripCarbonEstimate.TransportMode(rawValue: modeRaw) ?? .flight
    }

    var body: some View {
        if let kg = viewModel.roundTripCO2Kg(home: homeLocation, mode: mode) {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("trip.carbon.title", bundle: .main)
                            .font(.body.bold())
                        Text(verbatim: formattedValue(kg: kg))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker(selection: $unit) {
                        Text("trip.carbon.unit.kg", bundle: .main).tag("kg")
                        Text("trip.carbon.unit.lb", bundle: .main).tag("lb")
                    } label: {
                        Text("trip.carbon.unit.label", bundle: .main)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 110)
                }
                .accessibilityElement(children: .combine)
                Picker(selection: $modeRaw) {
                    ForEach(TripCarbonEstimate.TransportMode.allCases, id: \.rawValue) { value in
                        Text(localizedKey: "trip.carbon.mode.\(value.rawValue)")
                            .tag(value.rawValue)
                    }
                } label: {
                    Text("trip.carbon.mode.label", bundle: .main)
                }
            } footer: {
                Text("trip.carbon.footer", bundle: .main)
            }
        }
    }

    private func formattedValue(kg: Double) -> String {
        switch unit {
        case "lb":
            return String(format: "%.0f lb CO₂", kg * Self.kgToLb)
        default:
            return String(format: "%.0f kg CO₂", kg)
        }
    }
}

/// Round-14 slice 14: emergency contacts section.
struct TripEmergencyContactsSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var newLabel: String
    @Binding var newPhone: String

    /// Round-18 slice 13: builds a `tel:` URL by stripping every char except
    /// digits and a leading `+` so common formatting ("+34 600 11 22 33")
    /// doesn't break the dialer hand-off.
    static func telURL(from phone: String) -> URL? {
        var digits = phone.filter { $0.isNumber || $0 == "+" }
        if digits.contains("+") {
            // Keep only the first '+' and strip any others.
            let prefix = digits.first == "+" ? "+" : ""
            digits = prefix + digits.filter(\.isNumber)
        }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    var body: some View {
        Section {
            ForEach(viewModel.emergencyContacts) { contact in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: contact.label)
                            .font(.body)
                        Text(verbatim: contact.phone)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    if let url = Self.telURL(from: contact.phone) {
                        Link(destination: url) {
                            Image(systemName: "phone.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel(Text("trip.emergency.action.call", bundle: .main))
                    }
                }
                .accessibilityElement(children: .combine)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteEmergencyContact(contact)
                    } label: {
                        Label {
                            Text("common.delete", bundle: .main)
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            HStack {
                TextField(
                    text: $newLabel,
                    prompt: Text("trip.emergency.label.placeholder", bundle: .main)
                ) {
                    Text("trip.emergency.label", bundle: .main)
                }
                TextField(
                    text: $newPhone,
                    prompt: Text("trip.emergency.phone.placeholder", bundle: .main)
                ) {
                    Text("trip.emergency.phone", bundle: .main)
                }
                .keyboardType(.phonePad)
                Button {
                    viewModel.addEmergencyContact(label: newLabel, phone: newPhone)
                    newLabel = ""
                    newPhone = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Text("trip.emergency.action.add", bundle: .main))
                .disabled(newLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || newPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("trip.detail.section.emergency", bundle: .main)
        } footer: {
            Text("trip.detail.section.emergency.footer", bundle: .main)
        }
    }
}

/// Round-13 slice 4: surface the captured currency snapshot inline so the
/// user can see what was archived alongside the trip without opening the PDF.
struct TripCurrencySnapshotSection: View {
    let viewModel: TripDetailViewModel

    var body: some View {
        let snapshot = viewModel.capturedCurrencySnapshot
        if !snapshot.isEmpty {
            Section {
                ForEach(snapshot) { entry in
                    HStack {
                        Text(verbatim: String(
                            format: "%.2f %@ → %@",
                            entry.amount, entry.from, entry.to
                        ))
                        .font(.caption)
                        Spacer()
                        Text(verbatim: String(format: "%.2f", entry.amountConverted))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("trip.detail.section.currencySnapshot", bundle: .main)
            } footer: {
                Text("trip.detail.section.currencySnapshot.footer", bundle: .main)
            }
        }
    }
}

/// Round-13 slice 10: free-form trip expenses list.
struct TripExpensesSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var newLabel: String
    @Binding var newAmount: String
    @Binding var newCurrency: String

    var body: some View {
        Section {
            ForEach(viewModel.expenses) { expense in
                HStack {
                    Text(verbatim: expense.label)
                    Spacer()
                    Text(verbatim: String(format: "%.2f %@", expense.amount, expense.currencyCode))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteExpense(expense)
                    } label: {
                        Label {
                            Text("common.delete", bundle: .main)
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            HStack {
                TextField(
                    text: $newLabel,
                    prompt: Text("trip.expense.label.placeholder", bundle: .main)
                ) {
                    Text("trip.expense.label", bundle: .main)
                }
                TextField(
                    text: $newAmount,
                    prompt: Text(verbatim: "0.00")
                ) {
                    Text("trip.expense.amount", bundle: .main)
                }
                .keyboardType(.decimalPad)
                .frame(maxWidth: 80)
                TextField(
                    text: $newCurrency,
                    prompt: Text(verbatim: "USD")
                ) {
                    Text("trip.expense.currency", bundle: .main)
                }
                .textInputAutocapitalization(.characters)
                .frame(maxWidth: 60)
                Button {
                    if let amount = Double(newAmount) {
                        viewModel.addExpense(
                            label: newLabel,
                            amount: amount,
                            currencyCode: newCurrency
                        )
                        newLabel = ""
                        newAmount = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Text("trip.expense.action.add", bundle: .main))
                .disabled(newLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || Double(newAmount) == nil
                    || newCurrency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            // Round-18 slice 14: monthly summary disclosure.
            let buckets = TripExpenseMonthlySummary.buckets(from: viewModel.expenses)
            if !buckets.isEmpty {
                DisclosureGroup {
                    ForEach(buckets) { bucket in
                        HStack {
                            Text(verbatim: TripExpenseMonthlySummary.formattedMonth(
                                year: bucket.year,
                                month: bucket.month
                            ))
                            .font(.caption.monospacedDigit())
                            Spacer()
                            Text(verbatim: String(format: "%.2f %@ · %d",
                                                  bucket.total, bucket.currencyCode, bucket.count))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    Text("trip.expense.monthly.title", bundle: .main)
                }
            }
            // Round-19 slice T4.15: per-trip "convert all expenses" button
            // that prints + copies a per-currency total using the last
            // recorded conversion rate (offline, single-tap).
            if !viewModel.expenses.isEmpty {
                Button {
                    UIPasteboard.general.string = viewModel.convertedExpensesSummary()
                } label: {
                    Label {
                        Text("trip.expense.convertAll.action", bundle: .main)
                    } icon: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                }
            }
        } header: {
            Text("trip.detail.section.expenses", bundle: .main)
        }
    }
}
