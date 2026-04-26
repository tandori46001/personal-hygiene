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
