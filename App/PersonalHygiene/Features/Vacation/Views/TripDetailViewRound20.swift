import SwiftUI
import UIKit

/// Round-13 slice 10: free-form trip expenses list.
/// Hosted in this file (formerly in TripDetailViewRound12.swift) to keep
/// that file under SwiftLint's 500-line cap after round-20 additions.
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
                            Text(verbatim: String(
                                format: "%.2f %@ · %d",
                                bucket.total, bucket.currencyCode, bucket.count
                            ))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    Text("trip.expense.monthly.title", bundle: .main)
                }
            }
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
