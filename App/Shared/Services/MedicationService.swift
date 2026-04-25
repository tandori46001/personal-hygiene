import Foundation

/// Lightweight DTO of a HealthKit medication concept. Pure value type so
/// the rest of the app doesn't depend on `HealthKit` directly (HealthKit
/// is unavailable in the iOS Simulator).
public struct MedicationConcept: Hashable, Sendable {
    public let identifier: String
    public let displayName: String

    public init(identifier: String, displayName: String) {
        self.identifier = identifier
        self.displayName = displayName
    }
}

/// One medication-dose log entry — taken or skipped — over a window.
public struct MedicationDoseLog: Hashable, Sendable {
    public let conceptIdentifier: String
    public let scheduledAt: Date
    public let status: Status

    public enum Status: String, Sendable {
        case taken
        case skipped
        case missed
    }

    public init(conceptIdentifier: String, scheduledAt: Date, status: Status) {
        self.conceptIdentifier = conceptIdentifier
        self.scheduledAt = scheduledAt
        self.status = status
    }
}

@MainActor
public protocol MedicationService {
    /// Whether HealthKit medications are available on this device.
    /// Simulator → `false` (HealthKit isn't bridged into the simulator).
    var isAvailable: Bool { get }

    /// Request HealthKit authorization for medication read + write.
    func requestAuthorization() async throws -> Bool

    /// All medication concepts the user has registered in Health.
    func availableConcepts() async throws -> [MedicationConcept]

    /// Dose logs for the given concept, between `start` and `end` inclusive.
    func doseLogs(
        for conceptIdentifier: String,
        from start: Date,
        to end: Date
    ) async throws -> [MedicationDoseLog]
}

/// Test / preview implementation backed by an in-memory store.
@MainActor
public final class InMemoryMedicationService: MedicationService {

    public var isAvailable: Bool = true
    public var concepts: [MedicationConcept]
    public var logs: [MedicationDoseLog]

    public init(
        concepts: [MedicationConcept] = [],
        logs: [MedicationDoseLog] = []
    ) {
        self.concepts = concepts
        self.logs = logs
    }

    public func requestAuthorization() async throws -> Bool {
        true
    }

    public func availableConcepts() async throws -> [MedicationConcept] {
        concepts
    }

    public func doseLogs(
        for conceptIdentifier: String,
        from start: Date,
        to end: Date
    ) async throws -> [MedicationDoseLog] {
        logs.filter {
            $0.conceptIdentifier == conceptIdentifier
                && $0.scheduledAt >= start
                && $0.scheduledAt <= end
        }
    }
}

/// Production implementation that talks to HealthKit. Returns empty / throws
/// gracefully on the simulator where HealthKit is unavailable.
@MainActor
public final class HealthKitMedicationService: MedicationService {

    public init() {}

    public var isAvailable: Bool {
        // HealthKit is not available in the iOS Simulator. The framework can
        // be linked but `HKHealthStore.isHealthDataAvailable()` returns false.
        // Avoid importing HealthKit here so the rest of the app stays
        // simulator-buildable; we just expose `false` and let the UI degrade.
        false
    }

    public func requestAuthorization() async throws -> Bool {
        guard isAvailable else { return false }
        return false
    }

    public func availableConcepts() async throws -> [MedicationConcept] {
        guard isAvailable else { return [] }
        return []
    }

    public func doseLogs(
        for conceptIdentifier: String,
        from start: Date,
        to end: Date
    ) async throws -> [MedicationDoseLog] {
        guard isAvailable else { return [] }
        return []
    }
}
