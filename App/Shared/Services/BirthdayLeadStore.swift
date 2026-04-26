import Foundation

/// Per-contact override for "how many days before the birthday should we
/// surface a heads-up". The contact framework itself is read-only, so we
/// store overrides in `UserDefaults` keyed by the contact identifier.
public protocol BirthdayLeadStore: Sendable {
    /// `nil` means "use the global default" rather than "0 days".
    func leadDays(for contactIdentifier: String) -> Int?
    func setLeadDays(_ value: Int?, for contactIdentifier: String)
}

public final class UserDefaultsBirthdayLeadStore: BirthdayLeadStore, @unchecked Sendable {

    public static let storageKey = "personal-hygiene.birthdayLeadDays.v1"
    public static let defaultLeadDays = 7

    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func leadDays(for contactIdentifier: String) -> Int? {
        lock.lock(); defer { lock.unlock() }
        let map = readMap()
        return map[contactIdentifier]
    }

    public func setLeadDays(_ value: Int?, for contactIdentifier: String) {
        lock.lock(); defer { lock.unlock() }
        var map = readMap()
        if let value, value >= 0 {
            map[contactIdentifier] = value
        } else {
            map.removeValue(forKey: contactIdentifier)
        }
        defaults.set(map, forKey: Self.storageKey)
    }

    private func readMap() -> [String: Int] {
        defaults.dictionary(forKey: Self.storageKey) as? [String: Int] ?? [:]
    }
}

public final class InMemoryBirthdayLeadStore: BirthdayLeadStore, @unchecked Sendable {
    private var map: [String: Int] = [:]
    private let lock = NSLock()

    public init() {}

    public func leadDays(for contactIdentifier: String) -> Int? {
        lock.lock(); defer { lock.unlock() }
        return map[contactIdentifier]
    }

    public func setLeadDays(_ value: Int?, for contactIdentifier: String) {
        lock.lock(); defer { lock.unlock() }
        if let value, value >= 0 {
            map[contactIdentifier] = value
        } else {
            map.removeValue(forKey: contactIdentifier)
        }
    }
}
