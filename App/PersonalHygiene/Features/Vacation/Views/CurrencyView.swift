import SwiftUI

struct CurrencyView: View {

    let service: any CurrencyService

    @AppStorage("currencyFromCode") private var fromCode = "EUR"
    @AppStorage("currencyToCode") private var toCode = "USD"
    @State private var amountText = "100"
    @State private var conversion: CurrencyConversion?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        Form {
            Section {
                TextField(
                    text: $amountText,
                    prompt: Text(verbatim: "100")
                ) {
                    Text("trip.currency.field.amount", bundle: .main)
                }
                .keyboardType(.decimalPad)

                TextField(
                    text: $fromCode,
                    prompt: Text(verbatim: "EUR")
                ) {
                    Text("trip.currency.field.from", bundle: .main)
                }
                .textInputAutocapitalization(.characters)

                TextField(
                    text: $toCode,
                    prompt: Text(verbatim: "USD")
                ) {
                    Text("trip.currency.field.to", bundle: .main)
                }
                .textInputAutocapitalization(.characters)
            }

            Section {
                Button {
                    Task { await convert() }
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("trip.currency.action.converting", bundle: .main)
                        }
                    } else {
                        Text("trip.currency.action.convert", bundle: .main)
                    }
                }
                .disabled(isLoading || Double(amountText) == nil)
            }

            if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage, onDismiss: { self.errorMessage = nil })
                }
            }

            if let conversion {
                Section {
                    LabeledContent {
                        Text(verbatim: String(format: "%.2f %@", conversion.amountConverted, conversion.to))
                    } label: {
                        Text("trip.currency.label.converted", bundle: .main)
                    }
                    LabeledContent {
                        Text(verbatim: String(format: "%.4f", conversion.rate))
                    } label: {
                        Text("trip.currency.label.rate", bundle: .main)
                    }
                }
            }
        }
        .navigationTitle(Text("trip.currency.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func convert() async {
        guard let amount = Double(amountText) else { return }
        isLoading = true
        errorMessage = nil
        do {
            conversion = try await service.convert(amount: amount, from: fromCode, to: toCode)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
