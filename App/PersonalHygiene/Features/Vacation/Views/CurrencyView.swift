import SwiftUI

struct CurrencyView: View {

    let service: any CurrencyService

    /// Round-10 extra: G7-ish destination shortlist so the user can tap a
    /// currency without typing on iPhone. Order matches the rough frequency
    /// of the user's actual trips (USD/CAD first since they border, then
    /// the European cluster, then JPY for the Asian leg).
    static let supportedCodes = ["USD", "EUR", "GBP", "CAD", "CHF", "AUD", "JPY"]

    @AppStorage("currencyFromCode") private var fromCode = "EUR"
    @AppStorage("currencyToCode") private var toCode = "USD"
    @State private var amountText = "100"
    @State private var conversion: CurrencyConversion?
    @State private var allConversions: [CurrencyConversion] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var recents: [RecentConversionsStore.Entry] = []
    @State private var lastConversion: LastConversionStore.Entry?

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
                quickPickRow(binding: $fromCode, title: "trip.currency.quick.from")

                TextField(
                    text: $toCode,
                    prompt: Text(verbatim: "USD")
                ) {
                    Text("trip.currency.field.to", bundle: .main)
                }
                .textInputAutocapitalization(.characters)
                quickPickRow(binding: $toCode, title: "trip.currency.quick.to")
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

                Button {
                    Task { await convertAll() }
                } label: {
                    Text("trip.currency.action.convertAll", bundle: .main)
                }
                .disabled(isLoading || Double(amountText) == nil)
            } footer: {
                Text("trip.currency.action.convertAll.footer", bundle: .main)
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

            if !allConversions.isEmpty {
                Section {
                    ForEach(allConversions, id: \.to) { conv in
                        LabeledContent {
                            Text(verbatim: String(format: "%.2f %@", conv.amountConverted, conv.to))
                                .font(.system(.body, design: .monospaced))
                        } label: {
                            Text(verbatim: conv.to)
                        }
                    }
                } header: {
                    Text("trip.currency.section.allRates", bundle: .main)
                }
            }

            if !recents.isEmpty {
                Section {
                    ForEach(recents) { entry in
                        Button {
                            amountText = String(entry.amount)
                            fromCode = entry.from
                            toCode = entry.to
                        } label: {
                            HStack {
                                Text(verbatim: String(format: "%.2f %@ → %@", entry.amount, entry.from, entry.to))
                                    .font(.callout)
                                Spacer()
                                Text(verbatim: String(format: "%.2f", entry.amountConverted))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Button(role: .destructive) {
                        RecentConversionsStore.clear()
                        recents = []
                    } label: {
                        Text("trip.currency.recents.clear", bundle: .main)
                    }
                } header: {
                    Text("trip.currency.section.recents", bundle: .main)
                }
            }
        }
        .navigationTitle(Text("trip.currency.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recents = RecentConversionsStore.recent()
            // Round-12 slice 3: rehydrate last conversion so the rate panel
            // keeps showing data after navigating away and back without forcing
            // a fresh network call.
            if conversion == nil, let last = LastConversionStore.load() {
                lastConversion = last
                amountText = String(last.amount)
                fromCode = last.from
                toCode = last.to
                conversion = CurrencyConversion(
                    from: last.from,
                    to: last.to,
                    rate: last.rate,
                    amountConverted: last.amountConverted
                )
            }
        }
    }

    @ViewBuilder
    private func quickPickRow(binding: Binding<String>, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title, bundle: .main)
                .font(.caption2)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Self.supportedCodes, id: \.self) { code in
                        Button {
                            binding.wrappedValue = code
                        } label: {
                            Text(verbatim: code)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .tint(binding.wrappedValue.uppercased() == code ? .accentColor : .secondary)
                        .accessibilityLabel(
                            Text("trip.currency.quickPick.label \(code)", bundle: .main)
                        )
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func convert() async {
        guard let amount = Double(amountText) else { return }
        isLoading = true
        errorMessage = nil
        allConversions = []
        do {
            let result = try await service.convert(amount: amount, from: fromCode, to: toCode)
            conversion = result
            RecentConversionsStore.record(result, amount: amount)
            LastConversionStore.save(result, amount: amount)
            recents = RecentConversionsStore.recent()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func convertAll() async {
        guard let amount = Double(amountText) else { return }
        isLoading = true
        errorMessage = nil
        conversion = nil
        do {
            let targets = Self.supportedCodes.filter { $0 != fromCode.uppercased() }
            allConversions = try await service.convertAll(amount: amount, from: fromCode, to: targets)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
