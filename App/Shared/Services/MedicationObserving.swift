import Foundation

/// Observer abstraction for live medication-dose updates. Production wires
/// this to `HKObserverQuery` once the HealthKit `health.records.medications`
/// entitlement is granted; until then `MedicationObserverService.isAvailable`
/// stays `false` and the app falls back to the
/// `MedicationFollowUpFactory` push-reminder path (PRD M3.2).
///
/// Tests use `MockMedicationObserver` to verify call sites without HealthKit.
@MainActor
public protocol MedicationObserving: AnyObject {

    /// Whether the underlying observer can fire callbacks. `false` when the
    /// HealthKit entitlement is missing or the device lacks HealthKit
    /// (iOS Simulator) — callers should treat the M3.2 follow-up reminder
    /// path as the source of truth in that case.
    var isAvailable: Bool { get }

    /// Begin watching `conceptIdentifier`; `onChange` fires whenever a new
    /// dose log appears for that concept. Calling `start` twice for the
    /// same identifier is idempotent — the second `onChange` replaces the
    /// first (last-writer-wins) so we don't accumulate duplicate handlers.
    func start(
        for conceptIdentifier: String,
        onChange: @escaping @MainActor () -> Void
    )

    /// Stop watching `conceptIdentifier`; calling on an unregistered
    /// identifier is a no-op.
    func stop(for conceptIdentifier: String)

    /// Stop every active observer; useful between test runs.
    func stopAll()
}

/// In-memory mock used by unit tests. Records `start`/`stop` calls,
/// fires registered handlers via `simulateChange(for:)`. Idempotent on
/// duplicate `start` (last handler wins) per protocol contract.
@MainActor
public final class MockMedicationObserver: MedicationObserving {

    public var isAvailable: Bool = true

    private var handlers: [String: () -> Void] = [:]

    public private(set) var startedIdentifiers: [String] = []
    public private(set) var stoppedIdentifiers: [String] = []

    public init() {}

    public func start(
        for conceptIdentifier: String,
        onChange: @escaping @MainActor () -> Void
    ) {
        handlers[conceptIdentifier] = onChange
        startedIdentifiers.append(conceptIdentifier)
    }

    public func stop(for conceptIdentifier: String) {
        guard handlers.removeValue(forKey: conceptIdentifier) != nil else { return }
        stoppedIdentifiers.append(conceptIdentifier)
    }

    public func stopAll() {
        for key in handlers.keys {
            stoppedIdentifiers.append(key)
        }
        handlers.removeAll()
    }

    /// Test-only: invokes the registered handler for `conceptIdentifier`.
    /// No-op if no handler is registered.
    public func simulateChange(for conceptIdentifier: String) {
        handlers[conceptIdentifier]?()
    }

    /// Test introspection: how many handlers are currently registered.
    public var activeHandlerCount: Int { handlers.count }
}
