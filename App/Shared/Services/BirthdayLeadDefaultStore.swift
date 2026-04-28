import Foundation

/// Round-21 slice T6.32: global override for the per-contact lead-time
/// default. `UserDefaultsBirthdayLeadStore.defaultLeadDays` is currently a
/// static constant (7); this store layers a user-tunable value on top so the
/// Settings UI can change the default without touching individual contacts.
public enum BirthdayLeadDefaultStore {

    public static let key = "birthdays.globalLeadDaysDefault"
    public static let allowedRange = 0...60

    /// Effective default the rest of the app should consult when a contact
    /// has no per-contact override. Falls back to the legacy constant.
    public static func effectiveDefault(in defaults: UserDefaults = .standard) -> Int {
        if let stored = defaults.object(forKey: key) as? Int, allowedRange.contains(stored) {
            return stored
        }
        return UserDefaultsBirthdayLeadStore.defaultLeadDays
    }

    public static func setDefault(_ value: Int, in defaults: UserDefaults = .standard) {
        let clamped = max(allowedRange.lowerBound, min(allowedRange.upperBound, value))
        defaults.set(clamped, forKey: key)
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
