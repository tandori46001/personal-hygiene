import Foundation

/// Round-12 slice 5: deep link into Australia's `smartraveller.gov.au`
/// destination pages. Slug structure mirrors travel.gc.ca + gov.uk — the
/// auto-slug works for the long tail; common destination overrides live in
/// `DestinationSlug.australia(_:)`.
public struct AustraliaAdvisoryService: TravelAdvisoryService {

    public static let indexURL = URL(
        string: "https://www.smartraveller.gov.au/destinations"
    )!

    public init() {}

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return TravelAdvisoryLink(
                displayName: "smartraveller.gov.au",
                url: Self.indexURL,
                source: "smartraveller.gov.au"
            )
        }
        let slug = DestinationSlug.australia(trimmed)
        let url = URL(string: "https://www.smartraveller.gov.au/destinations/\(slug)")
            ?? Self.indexURL
        return TravelAdvisoryLink(
            displayName: trimmed,
            url: url,
            source: "smartraveller.gov.au"
        )
    }
}
