import Foundation

public struct TravelAdvisoryLink: Equatable, Sendable {
    public let displayName: String
    public let url: URL
    public let source: String

    public init(displayName: String, url: URL, source: String) {
        self.displayName = displayName
        self.url = url
        self.source = source
    }
}

public protocol TravelAdvisoryService: Sendable {
    func advisory(forDestination name: String) -> TravelAdvisoryLink

    /// Multi-source advisory list. Round-10 extra: returns deep links into
    /// every recognized authoritative foreign-affairs source (Spain
    /// Exteriores, US State Dept, Canada travel.gc.ca, UK FCDO, EU
    /// re-use). Default impl wraps the single-source result so existing
    /// implementations stay backward-compatible.
    func advisories(forDestination name: String) -> [TravelAdvisoryLink]
}

extension TravelAdvisoryService {
    public func advisories(forDestination name: String) -> [TravelAdvisoryLink] {
        [advisory(forDestination: name)]
    }
}

/// Builds a deep link into the Spanish foreign ministry's travel-advisory
/// section. There's no structured JSON feed — the official guidance lives in
/// per-country web pages — so the safest UX is to bounce the user directly to
/// the index page (which has its own search) with the destination name passed
/// along where possible.
public struct ExterioresAdvisoryService: TravelAdvisoryService {

    public static let indexURL = URL(
        string: "https://www.exteriores.gob.es/es/ServiciosAlCiudadano/Paginas/Recomendaciones-de-Viaje.aspx"
    )!

    public init() {}

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let url: URL
        if trimmed.isEmpty {
            url = Self.indexURL
        } else {
            var components = URLComponents(url: Self.indexURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
            url = components.url ?? Self.indexURL
        }
        return TravelAdvisoryLink(
            displayName: trimmed.isEmpty ? "exteriores.gob.es" : trimmed,
            url: url,
            source: "exteriores.gob.es"
        )
    }
}

/// Deep link into the US Department of State country-information lookup. The
/// canonical search URL accepts the country name in the path; we bounce to
/// the index when the destination is empty.
public struct StateDepartmentAdvisoryService: TravelAdvisoryService {

    public static let indexURL = URL(
        string: "https://travel.state.gov/content/travel/en/international-travel/International-Travel-Country-Information-Pages.html"
    )!

    public init() {}

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let url: URL
        if trimmed.isEmpty {
            url = Self.indexURL
        } else {
            // The /traveladvisories search endpoint accepts a `country=` param
            // and returns the matched country page when it exists, falling
            // back to the index otherwise.
            var components = URLComponents(
                string: "https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.html"
            )!
            components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
            url = components.url ?? Self.indexURL
        }
        return TravelAdvisoryLink(
            displayName: trimmed.isEmpty ? "travel.state.gov" : trimmed,
            url: url,
            source: "travel.state.gov"
        )
    }
}

/// Deep link into Global Affairs Canada's `travel.gc.ca` country listing.
public struct CanadaTravelAdvisoryService: TravelAdvisoryService {

    public static let indexURL = URL(
        string: "https://travel.gc.ca/destinations"
    )!

    public init() {}

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return TravelAdvisoryLink(
                displayName: "travel.gc.ca",
                url: Self.indexURL,
                source: "travel.gc.ca"
            )
        }
        let slug = DestinationSlug.canada(trimmed)
        let url = URL(string: "https://travel.gc.ca/destinations/\(slug)") ?? Self.indexURL
        return TravelAdvisoryLink(
            displayName: trimmed,
            url: url,
            source: "travel.gc.ca"
        )
    }
}

/// Deep link into the UK Foreign, Commonwealth & Development Office advisory
/// pages on `gov.uk`. Pages live at `/foreign-travel-advice/<slug>`.
public struct UKFCDOAdvisoryService: TravelAdvisoryService {

    public static let indexURL = URL(
        string: "https://www.gov.uk/foreign-travel-advice"
    )!

    public init() {}

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return TravelAdvisoryLink(
                displayName: "gov.uk · FCDO",
                url: Self.indexURL,
                source: "gov.uk · FCDO"
            )
        }
        let slug = DestinationSlug.ukFCDO(trimmed)
        let url = URL(string: "https://www.gov.uk/foreign-travel-advice/\(slug)") ?? Self.indexURL
        return TravelAdvisoryLink(
            displayName: trimmed,
            url: url,
            source: "gov.uk · FCDO"
        )
    }
}

/// Aggregates multiple advisory services into a single source the trip view
/// can consume. Order is preserved: list begins with the user's "primary"
/// (Spain in this single-user app), followed by US/Canada/UK so cross-checks
/// are quick. Backward-compatible single `advisory(forDestination:)` returns
/// the first entry — used by callers that haven't migrated to the list API.
public struct MultiSourceAdvisoryService: TravelAdvisoryService {

    public let upstreams: [any TravelAdvisoryService]

    public init(upstreams: [any TravelAdvisoryService]) {
        self.upstreams = upstreams
    }

    /// Default lineup: ES → US → CA → UK → AU. Single-user app, so there's
    /// no need to make this dynamic per-user yet; revisit if other locales
    /// become primary.
    public static func standard() -> Self {
        Self(upstreams: [
            ExterioresAdvisoryService(),
            StateDepartmentAdvisoryService(),
            CanadaTravelAdvisoryService(),
            UKFCDOAdvisoryService(),
            AustraliaAdvisoryService(),
        ])
    }

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        upstreams.first?.advisory(forDestination: name)
            ?? ExterioresAdvisoryService().advisory(forDestination: name)
    }

    public func advisories(forDestination name: String) -> [TravelAdvisoryLink] {
        upstreams.map { $0.advisory(forDestination: name) }
    }
}
