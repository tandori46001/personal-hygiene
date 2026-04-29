import Foundation

/// Round 27 follow-up: persistent FULL ordering of travel-advisory
/// sources. Distinct from the older `PreferredAdvisorySourceStore`
/// which only persisted a single "lead" choice. User reorders via
/// Settings → Days & Reminders → "Advisory sources".
///
/// New default order: US → Canada → UK → Australia → Spain (user
/// request — US first as the most thorough English-language source).
public enum AdvisoryOrderStore {

    public static let defaultsKey = "settings.advisory.order.v1"

    public static let defaultOrder: [AdvisorySource] = [
        .stateDept, .canada, .ukFCDO, .australia, .exteriores,
    ]

    public static func currentOrder(in defaults: UserDefaults = .standard) -> [AdvisorySource] {
        guard
            let raw = defaults.array(forKey: defaultsKey) as? [String]
        else { return defaultOrder }
        let parsed = raw.compactMap(AdvisorySource.init(rawValue:))
        // Append any future-added source the user hasn't seen yet so
        // the editor stays complete after a SDK update.
        let missing = defaultOrder.filter { !parsed.contains($0) }
        return parsed + missing
    }

    public static func setOrder(_ order: [AdvisorySource], in defaults: UserDefaults = .standard) {
        defaults.set(order.map(\.rawValue), forKey: defaultsKey)
    }

    public static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: defaultsKey)
    }
}
