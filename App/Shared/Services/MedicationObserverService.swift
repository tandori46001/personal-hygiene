import Foundation

/// Production-side `MedicationObserving` shell. Returns `isAvailable == false`
/// until the `health.records.medications` HealthKit entitlement ships with
/// the paid Apple Developer Program — at which point the implementation will
/// wrap `HKObserverQuery` and execute background sample queries on each fire.
///
/// Until then this class exists so the rest of the app can compile against
/// the protocol; calls to `start` / `stop` are recorded but never produce
/// callbacks. The push-reminder fallback (`MedicationFollowUpFactory`,
/// scheduled by `NotificationCoordinator.refreshForToday`) is the source of
/// truth for M3.2 in the meantime.
@MainActor
public final class MedicationObserverService: MedicationObserving {

    /// Always `false` until the entitlement + HealthKit sample type wiring
    /// land. Gate any caller logic on this flag.
    public var isAvailable: Bool { false }

    private var registered: Set<String> = []

    public init() {}

    public func start(
        for conceptIdentifier: String,
        onChange: @escaping @MainActor () -> Void
    ) {
        guard isAvailable else {
            // Pre-entitlement: record the registration so a future
            // `HKObserverQuery`-backed implementation can replay them once
            // available. No callback fires today.
            registered.insert(conceptIdentifier)
            return
        }
    }

    public func stop(for conceptIdentifier: String) {
        registered.remove(conceptIdentifier)
    }

    public func stopAll() {
        registered.removeAll()
    }
}
