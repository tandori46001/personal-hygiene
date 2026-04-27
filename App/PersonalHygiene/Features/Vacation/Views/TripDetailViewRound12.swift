import SwiftUI

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
        } header: {
            Text("trip.detail.section.expenses", bundle: .main)
        }
    }
}
