import Foundation
#if canImport(HealthKit) && !os(watchOS)
@preconcurrency import HealthKit
#endif

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

    /// Round-12 slice 4: runtime-aware availability. We still gate on the
    /// (not-yet-shipped) `health.records.medications` entitlement, but at
    /// least surface whether the device itself has HealthKit data available
    /// — that flips an additional row in DiagnosticsView and lets future
    /// wiring honor the OS-level capability check.
    public var isAvailable: Bool {
        guard isEntitlementGranted else { return false }
        #if canImport(HealthKit) && !os(watchOS)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Lifted to a stored property so the test double + future entitlement
    /// path can override it without touching framework state.
    public var isEntitlementGranted: Bool = false

    private var registered: Set<String> = []

    /// Snapshot of currently-registered concept identifiers — exposed to
    /// `DiagnosticsView` so the on-device user can see which medication
    /// concepts the app *would* observe once HealthKit lands. Sorted for
    /// deterministic UI ordering.
    public var registeredIdentifiers: [String] { registered.sorted() }

    public init() {}

    public func start(
        for conceptIdentifier: String,
        onChange: @escaping @MainActor () -> Void
    ) {
        // Always record the registration so DiagnosticsView can surface what
        // *would* be observed. Pre-entitlement (`isAvailable == false`) we
        // never fire callbacks; the M3.2 follow-up reminder path is the
        // source of truth in that case.
        registered.insert(conceptIdentifier)
        guard isAvailable else { return }
    }

    public func stop(for conceptIdentifier: String) {
        registered.remove(conceptIdentifier)
    }

    public func stopAll() {
        registered.removeAll()
    }
}
