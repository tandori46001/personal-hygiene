@preconcurrency import MapKit
import Observation
import SwiftUI

/// Round 27 follow-up: autocomplete for trip destination using
/// `MKLocalSearchCompleter`. Apple-native, no API keys, free.
///
/// As the user types, MapKit returns up to ~10 ranked completions
/// (cities, countries, landmarks). Tapping a suggestion resolves it
/// via `MKLocalSearch` to a real placemark and writes back the
/// canonical name + lat/lng to the bindings.
@Observable
@MainActor
final class LocationCompletionsProvider: NSObject {

    var completions: [MKLocalSearchCompletion] = []
    var query: String = "" {
        didSet { completer.queryFragment = query }
    }

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
    }

    /// Resolved placemark — name + coordinates as a single value type.
    /// Was previously a 3-tuple; SwiftLint's `large_tuple` rule caps at 2.
    struct ResolvedPlace: Equatable, Sendable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    /// Resolve a tapped suggestion to coordinates + canonical name.
    func resolve(_ completion: MKLocalSearchCompletion) async -> ResolvedPlace? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }
            let coord = item.placemark.coordinate
            // Prefer the placemark name + locality (e.g. "Tokyo, Japan")
            // over the bare item.name which is sometimes just the POI label.
            let name: String = {
                let placemark = item.placemark
                if let title = placemark.title { return title }
                return item.name ?? completion.title
            }()
            return ResolvedPlace(name: name, latitude: coord.latitude, longitude: coord.longitude)
        } catch {
            return nil
        }
    }
}

// `@preconcurrency` lives on the `import MapKit` line at the top of this
// file (round 29 / L009 fix). Adding it again on the conformance is
// redundant and the compiler diagnoses it as "has no effect" under
// SWIFT_STRICT_CONCURRENCY=complete (round 36 / Batch Q).
extension LocationCompletionsProvider: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // MKLocalSearchCompletion is non-Sendable, so we can't capture the
        // results array directly. Snapshot the title+subtitle and fetch
        // the live array on the main actor (delegate is already invoked
        // there by MapKit's contract).
        Task { @MainActor [weak self] in
            self?.completions = self?.refresh() ?? []
        }
    }

    @MainActor
    private func refresh() -> [MKLocalSearchCompletion] {
        completer.results
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.completions = []
        }
    }
}

/// SwiftUI field that combines a TextField + suggestion list. Designed
/// for use inside a Form. Selection writes to all 3 bindings atomically.
struct LocationAutocompleteField: View {

    @Binding var name: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    var label: LocalizedStringKey = "trips.field.destination"
    var placeholder: LocalizedStringKey = "trips.field.destination.placeholder"

    @State private var provider = LocationCompletionsProvider()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(
                text: $name,
                prompt: Text(placeholder, bundle: .main)
            ) {
                Text(label, bundle: .main)
            }
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onChange(of: name) { _, newValue in
                provider.query = newValue
            }

            if isFocused, !provider.completions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(provider.completions.prefix(6), id: \.self) { completion in
                        Button {
                            Task { await select(completion) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: completion.title)
                                    .font(.callout)
                                if !completion.subtitle.isEmpty {
                                    Text(verbatim: completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        if completion != provider.completions.prefix(6).last {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func select(_ completion: MKLocalSearchCompletion) async {
        if let resolved = await provider.resolve(completion) {
            name = resolved.name
            latitude = resolved.latitude
            longitude = resolved.longitude
        } else {
            // Resolution failed — fall back to the suggestion text only,
            // leave coordinates untouched so the user can pick a different
            // suggestion.
            name = completion.title
        }
        provider.completions = []
        isFocused = false
    }
}

/// SwiftUI Map preview pinned to the resolved destination. Hides
/// itself when no coordinates are set. Read-only by design — the
/// user moves the pin by re-typing in the autocomplete field.
struct DestinationMapPreview: View {

    let name: String
    let latitude: Double?
    let longitude: Double?

    var body: some View {
        if let lat = latitude, let lng = longitude {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))) {
                Marker(name, coordinate: coord)
                    .tint(.red)
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
