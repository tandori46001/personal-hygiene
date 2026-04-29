import SwiftData
import SwiftUI

/// Round 27 WS-A: 5-stage wizard that gathers itinerary preferences,
/// builds a prompt via `ItineraryPromptBuilder`, and lets the user
/// either run it on Apple Intelligence on-device or copy it to the
/// clipboard for pasting into Claude.ai / ChatGPT / Perplexity.
///
/// Stages are tabbed via a `TabView(.page)` style. Skip-stage / Back /
/// Next / Generate buttons sit in the toolbar. The request is persisted
/// into `Trip.itineraryRequestJSON` on every change so re-opening the
/// wizard pre-fills the previous answers.
struct ItineraryWizardView: View {

    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var request: TripItineraryRequest
    @State private var stage: Int = 0
    @State private var showingOutput = false

    init(trip: Trip) {
        self.trip = trip
        let decoded = TripItineraryRequest.decode(trip.itineraryRequestJSON)
        _request = State(initialValue: decoded ?? TripItineraryRequest.fresh(for: trip))
    }

    var body: some View {
        NavigationStack {
            VStack {
                progressIndicator
                ScrollView {
                    Group {
                        switch stage {
                        case 0: Stage1View(request: $request)
                        case 1: Stage2View(request: $request)
                        case 2: Stage3View(request: $request, trip: trip)
                        case 3: Stage4View(request: $request)
                        default: Stage5View(request: $request)
                        }
                    }
                    .padding()
                }
                stageToolbar
            }
            .navigationTitle(Text("itinerary.wizard.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        persist()
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
            }
            .onChange(of: request) { _, _ in persist() }
            .sheet(isPresented: $showingOutput) {
                ItineraryOutputView(request: request, trip: trip)
            }
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { idx in
                Capsule()
                    .fill(idx <= stage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stageToolbar: some View {
        HStack {
            if stage > 0 {
                Button {
                    stage -= 1
                } label: {
                    Text("itinerary.wizard.back", bundle: .main)
                }
            }
            Spacer()
            Button {
                stage = min(4, stage + 1)
            } label: {
                Text("itinerary.wizard.skip", bundle: .main)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if stage < 4 {
                Button {
                    stage += 1
                } label: {
                    Text("itinerary.wizard.next", bundle: .main)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    persist()
                    showingOutput = true
                } label: {
                    Text("itinerary.wizard.generate", bundle: .main)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func persist() {
        trip.itineraryRequestJSON = request.encoded()
        try? modelContext.save()
    }
}

extension TripItineraryRequest {

    /// Round 27 WS-A: pre-fill `nights` from the trip's date range.
    static func fresh(for trip: Trip) -> TripItineraryRequest {
        var req = TripItineraryRequest()
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        let nightCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        if nightCount > 0 {
            req.nights = (0..<nightCount).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: start).map { d in
                    NightAccommodation(date: d, cityArea: trip.destinationName)
                }
            }
        }
        return req
    }
}

// MARK: - Stages

private struct Stage1View: View {
    @Binding var request: TripItineraryRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("itinerary.wizard.stage1.title", bundle: .main)
                .font(.title2.bold())

            Stepper(
                value: $request.travellerCount,
                in: 1...12
            ) {
                Text("itinerary.wizard.stage1.count \(request.travellerCount)", bundle: .main)
            }

            TextField(
                text: $request.travellerNamesAndAges,
                prompt: Text("itinerary.wizard.stage1.names.placeholder", bundle: .main),
                axis: .vertical
            ) {
                Text("itinerary.wizard.stage1.names", bundle: .main)
            }
            .lineLimit(2, reservesSpace: true)

            MultiSelectChips(
                title: "itinerary.wizard.stage1.relationships",
                options: Relationship.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.relationships
            )

            SingleSelectPicker(
                title: "itinerary.wizard.stage1.fitness",
                options: FitnessLevel.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.fitness
            )

            MultiSelectChips(
                title: "itinerary.wizard.stage1.mobility",
                options: MobilityNeed.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.mobilityNeeds
            )

            MultiSelectChips(
                title: "itinerary.wizard.stage1.dietary",
                options: DietaryRestriction.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.dietaryRestrictions
            )
        }
    }
}

private struct Stage2View: View {
    @Binding var request: TripItineraryRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("itinerary.wizard.stage2.title", bundle: .main)
                .font(.title2.bold())

            SingleSelectPicker(
                title: "itinerary.wizard.stage2.vibe",
                options: TripVibe.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.vibe
            )

            MultiSelectChips(
                title: "itinerary.wizard.stage2.transport",
                options: TransportMode.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.transport
            )

            SingleSelectPicker(
                title: "itinerary.wizard.stage2.pace",
                options: Pace.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.pace
            )

            MultiSelectChips(
                title: "itinerary.wizard.stage2.avoid",
                options: Avoidance.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.avoidances
            )
        }
    }
}

private struct Stage3View: View {
    @Binding var request: TripItineraryRequest
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("itinerary.wizard.stage3.title", bundle: .main)
                .font(.title2.bold())
            ForEach($request.nights) { $night in
                NightRowEditor(night: $night)
            }
            if request.nights.contains(where: { !$0.booked }) {
                MultiSelectChips(
                    title: "itinerary.wizard.stage3.priorities",
                    options: AccommodationPriority.allCases,
                    label: { Text(verbatim: $0.rawValue.capitalized) },
                    selection: $request.accommodationPriorities
                )
            }
        }
    }
}

private struct NightRowEditor: View {
    @Binding var night: NightAccommodation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: nightDateLabel)
                    .font(.subheadline.bold())
                Spacer()
                Toggle(isOn: $night.booked) {
                    Text("itinerary.wizard.stage3.booked", bundle: .main)
                        .font(.caption)
                }
                .labelsHidden()
            }
            TextField(
                text: $night.cityArea,
                prompt: Text("itinerary.wizard.stage3.city.placeholder", bundle: .main)
            ) {
                Text("itinerary.wizard.stage3.city", bundle: .main)
            }
            Picker(
                selection: $night.type
            ) {
                Text("itinerary.wizard.stage3.type.none", bundle: .main).tag(AccommodationType?.none)
                ForEach(AccommodationType.allCases, id: \.self) { type in
                    Text(verbatim: type.rawValue.capitalized).tag(AccommodationType?.some(type))
                }
            } label: {
                Text("itinerary.wizard.stage3.type", bundle: .main)
            }
            .pickerStyle(.menu)
        }
        .padding(8)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var nightDateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: night.date)
    }
}

private struct Stage4View: View {
    @Binding var request: TripItineraryRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("itinerary.wizard.stage4.title", bundle: .main)
                .font(.title2.bold())

            MultiSelectChips(
                title: "itinerary.wizard.stage4.activities",
                options: Activity.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.mustDoActivities
            )
            MultiSelectChips(
                title: "itinerary.wizard.stage4.lovedCuisines",
                options: Cuisine.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.lovedCuisines
            )
            MultiSelectChips(
                title: "itinerary.wizard.stage4.avoidedCuisines",
                options: Cuisine.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.avoidedCuisines
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("itinerary.wizard.stage4.mustSee", bundle: .main)
                    .font(.subheadline.bold())
                TextField(
                    text: $request.mustSeePlaces,
                    prompt: Text("itinerary.wizard.stage4.mustSee.placeholder", bundle: .main),
                    axis: .vertical
                ) { EmptyView() }
                .lineLimit(3, reservesSpace: true)
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private struct Stage5View: View {
    @Binding var request: TripItineraryRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("itinerary.wizard.stage5.title", bundle: .main)
                .font(.title2.bold())

            SingleSelectPicker(
                title: "itinerary.wizard.stage5.budgetMode",
                options: BudgetMode.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.budgetMode
            )
            if request.budgetMode != nil && request.budgetMode != .unlimited {
                Stepper(
                    value: Binding(
                        get: { request.budgetAmount ?? 0 },
                        set: { request.budgetAmount = $0 }
                    ),
                    in: 0...50_000,
                    step: 100
                ) {
                    Text("itinerary.wizard.stage5.amount \(request.budgetAmount ?? 0)", bundle: .main)
                }
            }
            SingleSelectPicker(
                title: "itinerary.wizard.stage5.priority",
                options: BudgetPriority.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.budgetPriority
            )
            SingleSelectPicker(
                title: "itinerary.wizard.stage5.foodBudget",
                options: FoodBudget.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.foodBudgetPerMeal
            )
            SingleSelectPicker(
                title: "itinerary.wizard.stage5.visa",
                options: VisaStatus.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.visaStatus
            )
            SingleSelectPicker(
                title: "itinerary.wizard.stage5.insurance",
                options: TravelInsuranceStatus.allCases,
                label: { Text(verbatim: $0.rawValue.capitalized) },
                selection: $request.travelInsurance
            )
        }
    }
}

// MARK: - Reusable selectors

private struct MultiSelectChips<Option: Hashable & CaseIterable, Label: View>: View where Option.AllCases: RandomAccessCollection {
    let title: LocalizedStringKey
    let options: Option.AllCases
    @ViewBuilder let label: (Option) -> Label
    @Binding var selection: [Option]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title, bundle: .main)
                .font(.subheadline.bold())
            FlowLayout(spacing: 8) {
                ForEach(Array(options), id: \.self) { option in
                    Button {
                        if let idx = selection.firstIndex(of: option) {
                            selection.remove(at: idx)
                        } else {
                            selection.append(option)
                        }
                    } label: {
                        label(option)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                selection.contains(option) ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.12),
                                in: Capsule()
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SingleSelectPicker<Option: Hashable & CaseIterable, Label: View>: View where Option.AllCases: RandomAccessCollection {
    let title: LocalizedStringKey
    let options: Option.AllCases
    @ViewBuilder let label: (Option) -> Label
    @Binding var selection: Option?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title, bundle: .main)
                .font(.subheadline.bold())
            Picker(
                selection: $selection
            ) {
                Text("itinerary.wizard.unset", bundle: .main).tag(Option?.none)
                ForEach(Array(options), id: \.self) { option in
                    label(option).tag(Option?.some(option))
                }
            } label: { EmptyView() }
            .pickerStyle(.menu)
        }
    }
}

