import Foundation

/// Round-12 slice 40: per-block override of the medication follow-up delay.
/// Stored as a `[blockUUID: minutes]` JSON dictionary in UserDefaults so we
/// avoid a new SwiftData migration for what's effectively a per-user prefs
/// dict. `NotificationCoordinator.medicationFollowUps` consults this before
/// falling back to `MedicationFollowUpDelayStore`.
public enum PerBlockFollowUpOverrideStore {

    public static let key = "medication.followup.perBlockMinutes"

    public static func dictionary(defaults: UserDefaults = .standard) -> [String: Int] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    public static func minutes(
        for blockID: UUID,
        defaults: UserDefaults = .standard
    ) -> Int? {
        dictionary(defaults: defaults)[blockID.uuidString]
    }

    public static func set(
        _ minutes: Int?,
        for blockID: UUID,
        in defaults: UserDefaults = .standard
    ) {
        var current = dictionary(defaults: defaults)
        if let minutes,
           MedicationFollowUpDelayStore.allowedMinutes.contains(minutes) {
            current[blockID.uuidString] = minutes
        } else {
            current.removeValue(forKey: blockID.uuidString)
        }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clearAll(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
