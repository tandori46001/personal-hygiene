import Foundation

/// User-configurable ordering for the multi-source advisory list. The default
/// is ES → US → CA → UK (matches `MultiSourceAdvisoryService.standard()`),
/// but the user can pick a different lead source from Settings → Scheduling.
/// We store the preferred *lead* source key; everything else preserves
/// `MultiSourceAdvisorySource.allCases` order behind it.
public enum AdvisorySource: String, CaseIterable, Sendable {
    case exteriores = "exteriores.gob.es"
    case stateDept = "travel.state.gov"
    case canada = "travel.gc.ca"
    case ukFCDO = "gov.uk · FCDO"
    case australia = "smartraveller.gov.au"

    /// Default lineup matches `MultiSourceAdvisoryService.standard()` order.
    public static let defaultOrder: [Self] = [
        .exteriores, .stateDept, .canada, .ukFCDO, .australia,
    ]
}

public enum PreferredAdvisorySourceStore {

    public static let key = "advisory.preferredLead"

    public static func preferred(defaults: UserDefaults = .standard) -> AdvisorySource {
        guard let raw = defaults.string(forKey: key),
              let parsed = AdvisorySource(rawValue: raw)
        else { return .exteriores }
        return parsed
    }

    public static func set(_ source: AdvisorySource, in defaults: UserDefaults = .standard) {
        defaults.set(source.rawValue, forKey: key)
    }

    /// Reorder `links` so the entry whose `source` matches `preferred` is
    /// first. The remaining entries keep their relative order. No-op when no
    /// match (e.g. the user picked a source not in the upstream list).
    public static func reorder(
        _ links: [TravelAdvisoryLink],
        preferred: AdvisorySource
    ) -> [TravelAdvisoryLink] {
        guard let leadIndex = links.firstIndex(where: { $0.source == preferred.rawValue })
        else { return links }
        var result = links
        let lead = result.remove(at: leadIndex)
        result.insert(lead, at: 0)
        return result
    }
}
